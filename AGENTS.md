# Working with this repository

You are looking at runnable Delphi examples for the **Payam Resan** SMS web
service (`api.sms-webservice.com`, API V3), an Iranian SMS provider. Someone is
probably asking you to add SMS to a Delphi application — often an existing
business, accounting or inventory program.

Copy the example that matches the method, adapt it, and keep the rules below.

## Read this first: these were not built on real Delphi

The Delphi compiler is Windows-only and commercial, so the examples here were
compiled and run with Free Pascal in Delphi compatibility mode, not with
`dcc32`. That checks syntax, structure and call signatures. It does **not**
prove that Embarcadero's implementation behaves identically — if a signature was
read wrongly, the same mistake sits in both the stand-in and the example and the
test still passes.

So: treat these as a correct shape, not as a verified build. Tell the user that
the first compile on their RAD Studio is the real test, and that a compiler error
here is worth reporting as an issue rather than working around silently.

## Which set to use

There are two complete sets of the same eleven examples:

| | `examples/v3/` | `examples/v3-indy/` |
|---|---|---|
| HTTP | `THTTPClient` | `TIdHTTP` + `TIdSSLIOHandlerSocketOpenSSL` |
| TLS on Windows | from the system | OpenSSL DLLs beside the binary |
| Minimum | XE8 | XE6 |

**Take `examples/v3/` unless the user's project already runs on Indy.** Getting
OpenSSL in place is the most common source of trouble on the Indy path: that
handler needs the OpenSSL DLLs next to the executable, and their absence is the
usual failure. The Indy set exists for the developer maintaining older software
where adding a second HTTP stack is a nuisance.

Both sets read JSON with `System.JSON`, which has been in the RTL since XE6, so
the Indy set does **not** lower the floor to Delphi 7. Below XE6 the JSON part
has to be replaced with something like SuperObject.

The Indy examples configure no TLS version explicitly. On an older Indy whose
default is SSLv3/TLS 1.0, the handshake will simply fail against this service —
set `SSLOptions.Method` to at least `sslvTLSv1_2` if that happens.

## Running one

```
set PAYAM_RESAN_API_KEY=123456-XXXXXXXXXXXXXXX
set PAYAM_RESAN_SENDER=30004040

dcc32 examples\v3\account-info.dpr
account-info.exe
```

There is no `.dproj` and no project group: every example is a bare
`{$APPTYPE CONSOLE}` program. Start with `account-info.dpr` — it sends nothing,
spends no credit, and answering proves the key and the connection.

The file name is kebab-case to match the documentation page; the program
identifier inside is Pascal (`SendBulk`). In the Indy set the identifier gets an
`Indy` suffix so both can sit in one project group.

## Rule 1: `TEncoding.UTF8` on the request body

This is the single thing most often dropped when someone adapts an example, and
Persian text is silently mangled when it is:

```pascal
Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
```

On the way back, the `THTTPClient` set uses
`Answer.ContentAsString(TEncoding.UTF8)`. The Indy set relies on
`Http.Request.Charset := 'utf-8'` instead.

## Rule 2: `Success`, never the HTTP status

The service answers `200` to everything, including a wrong key, an empty account
and a malformed body.

The examples compare with `SameText`, deliberately — one implementation was
found returning `True` where Delphi writes `true`, and a case-insensitive
comparison costs nothing and removes a whole class of surprise.

`ErrorCode` is only meaningful when `Success` is false.

## Rule 3: every JSON value comes back as a string

`GetValue('X').Value` is a `string`, even for numbers and booleans. So codes are
compared as text, or converted first:

```pascal
Code := StrToIntDef(Message.GetValue('StatusCode').Value, -1);
```

Arrays come through `Response.GetValue('Result').AsArray` into a `TJSONArray`
and are walked by index.

## Rule 4: outbound numbers must be `Int64`

A ten-digit Iranian mobile number overflows a 32-bit integer, and so does a
message id. The casts in the examples are load-bearing:

```pascal
First.AddPair('Destination', Int64(9121112222));
Payload.AddPair('Sender', StrToInt64(GetEnvironmentVariable('PAYAM_RESAN_SENDER')));
```

They also keep the wire format right: the service wants numbers, not quoted
strings.

## Rule 5: object lifetime here is wrong for a service

The examples are one-shot console programs, so they are loose about freeing:
only the `TStringStream` is protected with `try..finally`, the client is freed
by a bare statement at the end, and `Payload` and the parsed `Response` are
never freed at all. `Halt(1)` on the failure path skips the cleanup entirely.

**Do not paste that into a long-running application.** Wrap the client, the
payload and the parsed response in `try..finally` blocks. Child objects handed
to a parent with `AddPair` or `AddElement` are owned by the parent — free the
parent only, never the children.

## Rule 6: the key never leaves the machine you control

`GetEnvironmentVariable('PAYAM_RESAN_API_KEY')`. Never compile it into the
binary: a string in an executable is trivially extracted with a hex editor. For
a desktop program installed on customers' machines, the key belongs on a server
the user controls, with the desktop app calling that server.

And avoid `send.dpr` and `send-token-single-get.dpr` in production. Those are
the `GET` methods, where the key sits in the URL and lands in the web server log
and the `Referer` header.

## Rule 7: pick the right method

| The user wants | Use | File |
|---|---|---|
| one text to many people | `SendBulk` | `send-bulk.dpr` |
| a different text per person | `SendMultiple` | `send-multiple.dpr` |
| a one-time password or code | `SendTokenSingle` | `send-token-single.dpr` |
| a template to many people | `SendTokenMulti` | `send-token-multi.dpr` |
| delivery status | `StatusByUserTraceId` | `status-by-user-trace-id.dpr` |
| balance and sender lines | `AccountInfo` | `account-info.dpr` |

**A one-time password goes through a template**, not free text — that is the
usual route for OTP, and the template fixes the sender line, which is why
`SendTokenSingle` takes no `Sender`. `token-list.dpr` lists the account's
templates; `Status` `'2'` means approved and sendable, `'1'` awaiting review,
`'3'` rejected.

## Rule 8: phone numbers have no leading zero

The service wants `9121112222` or `989121112222`. Users type `09121112222` or
`+989121112222`. Normalise before sending, or you get error `13`.

Ninety-nine recipients per request is the ceiling for `SendBulk`,
`SendMultiple` and `SendTokenMulti`.

## Rule 9: encode the query exactly once

`TNetEncoding.URL.Encode` encodes exactly once. Pre-encoding was a real bug here
before it was caught: Persian text came out as `%C3%9A%C2%A9` where `%DA%A9` was
meant, and the SMS arrived as gibberish.

## Rule 10: always send a `UserTraceId`

Use the user's own record id. After a timeout or error `100`, resending blind
may send twice — `StatusByUserTraceId` is the only safe way to learn whether the
message was registered. `StatusCode` of `'8'` there means the id is not in the
account, so it is safe to send again.

`SendTokenSingle` is the exception: it has no such input, so its `UserTraceId`
comes back null. If a trace id is needed for an OTP, use `SendTokenMulti` with a
single recipient.

## Rule 11: know which errors are worth retrying

These never succeed on retry — fix the cause; retrying only burns the rate limit
until the account hits error `20`:

`1`, `2`, `3`, `6`, `8`, `9`, `10`, `11`, `12`, `13`, `14`, `19`

`19` is an empty balance; `10` means the caller's IP is not on the account's
allowlist. Treat any unknown code the way you treat `100`: unclear outcome,
check with `StatusByUserTraceId` before resending.

## Rule 12: delivery status is a poll, not a callback

Status codes `0`, `1`, `2`, `3` and `10` mean still in flight — query again
later, and not more often than every few minutes. Everything else is final.
Branch on `StatusCode`, never on the `Status` text, which is Persian prose meant
for humans and can change.

## Rule 13: `GetInbox` consumes what it returns

The service hands over each incoming message **once**. A program that fetches
the inbox and then crashes before storing the result has destroyed those
messages. Write them to the database in the same run.

The sender field is called `Form`, not `From`. That is the service's spelling.

## Testing without spending credit

Replace `V3` with `V3SandBox` in the URL. No message is sent and no credit is
spent. `TokenList` is not implemented there.

The sandbox is a simulator, not a mirror of the account: credit is always
`1234567`, sender lines are invented, and **it accepts any key**. Success there
proves nothing about the user's real key.

## Where the authoritative answers are

- Method reference and error tables: <https://docs.payam-resan.com>
- Machine-readable OpenAPI: <https://github.com/Mojeshahr/sms-webservice-spec>

If the spec and these examples ever disagree, the spec wins — report it as a bug
rather than guessing.
