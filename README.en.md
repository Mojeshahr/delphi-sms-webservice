<div align="center">

<a href="https://payam-resan.com">
  <img src=".github/assets/logo.svg" width="64" height="64" alt="Payam Resan">
</a>

<h1>Delphi examples for the Payam Resan SMS web service</h1>

Talk to the <a href="https://payam-resan.com"><b>Payam Resan SMS panel</b></a> from Delphi<br>
One runnable file per API method, with no dependencies

[![API](https://img.shields.io/badge/API-V3-0a7cbd)](https://payam-resan.com)
[![Delphi](https://img.shields.io/badge/Delphi-XE8%2B-e62e2e)](https://www.embarcadero.com/products/delphi)
[![Dependencies](https://img.shields.io/badge/dependencies-none-2ea44f)](#quick-start)
[![License](https://img.shields.io/badge/license-MIT-6e7781)](LICENSE)

<a href="README.md">فارسی</a> · <b>English</b>

</div>

<sub>Looking for another language? The same examples exist for the others at
[github.com/Mojeshahr](https://github.com/Mojeshahr).</sub>

---

## Quick start

```
git clone https://github.com/Mojeshahr/delphi-sms-webservice.git
cd delphi-sms-webservice

set PAYAM_RESAN_API_KEY=123456-XXXXXXXXXXXXXXX
set PAYAM_RESAN_SENDER=30004040

dcc32 examples\v3\account-info.dpr
account-info.exe
```

No component to install and nothing from GetIt. Both `System.Net.HttpClient`
and `System.JSON` ship in the Delphi RTL.

Start with `account-info.dpr`. It sends nothing, spends no credit, and if it
answers then both the key and the connection are fine.

## Two sets of examples, on purpose

`examples/v3/` uses `THTTPClient`, which has been in the RTL since XE8, takes
its TLS from Windows itself, and needs nothing installed. If you are writing
something new, or your Delphi is current, take this one.

`examples/v3-indy/` has the same thirteen methods written with `TIdHTTP`. It is
for the developer maintaining older software whose whole project already runs
on Indy, where adding a second HTTP stack is a nuisance and rewriting is not an
option.

| | `examples/v3/` | `examples/v3-indy/` |
|---|---|---|
| Class | `THTTPClient` | `TIdHTTP` |
| Minimum version | XE8 | older releases too |
| TLS on Windows | from the system | OpenSSL DLLs beside the binary |
| Component to install | none | Indy ships with Delphi |

If you are free to choose, take the first set. Getting OpenSSL in place for
Indy is the most common source of trouble on that path.

## Before sending anything real

There is a sandbox server that answers exactly like production but sends no
message and spends no credit. Swap `V3` for `V3SandBox` in the URL. The one
exception is `TokenList`, which the sandbox does not implement.

## The methods

| Example | Method | What it does |
|---|---|---|
| [account-info.dpr](examples/v3/account-info.dpr) | `AccountInfo` | Credit and active lines |
| [send.dpr](examples/v3/send.dpr) | `Send` | Simple send over `GET` |
| [send-bulk.dpr](examples/v3/send-bulk.dpr) | `SendBulk` | One text to many recipients, with tracking ids |
| [send-multiple.dpr](examples/v3/send-multiple.dpr) | `SendMultiple` | A separate text per recipient |
| [token-list.dpr](examples/v3/token-list.dpr) | `TokenList` | The account's templates |
| [send-token-single.dpr](examples/v3/send-token-single.dpr) | `SendTokenSingle` | Send a template to one number |
| [send-token-single-get.dpr](examples/v3/send-token-single-get.dpr) | `SendTokenSingle` | The same, over `GET` |
| [send-token-single-concat-param.dpr](examples/v3/send-token-single-concat-param.dpr) | `SendTokenSingleConcatParam` | Template values in one semicolon-separated `p` string |
| [send-token-single-concat-param-get.dpr](examples/v3/send-token-single-concat-param-get.dpr) | `SendTokenSingleConcatParam` | The same, over `GET` |
| [send-token-multi.dpr](examples/v3/send-token-multi.dpr) | `SendTokenMulti` | One template, many recipients |
| [status-by-id.dpr](examples/v3/status-by-id.dpr) | `StatusById` | Status by the service's id |
| [status-by-user-trace-id.dpr](examples/v3/status-by-user-trace-id.dpr) | `StatusByUserTraceId` | Status by your own id |
| [get-inbox.dpr](examples/v3/get-inbox.dpr) | `GetInbox` | Messages people sent to your lines |

The same thirteen names exist under `examples/v3-indy/`.

## If it fails on your Delphi, please tell us

One thing is worth being plain about. The Delphi compiler is Windows-only and
commercial, so the examples here were compiled and run with Free Pascal in its
Delphi compatibility mode rather than with `dcc32` itself. How that works is
written up in [`testing/`](testing/).

That checks the syntax, the structure and the call signatures, but it is not a
substitute for one real build on RAD Studio.

So if you hit a compiler error, a warning, or different behaviour on your
version of Delphi, that is exactly what we want to hear. Open an
[issue](https://github.com/Mojeshahr/delphi-sms-webservice/issues) with your
Delphi version, the file name and the error text. Pull requests are welcome too.

An example that genuinely compiles on your version is worth more than one that
merely looks tidy.

## Things that will save you time

**Do not read the HTTP status code.** The service answers `200` to everything,
including a wrong key, so `Answer.StatusCode` proves nothing. Decide on the
`Success` field. Every example here does.

**Build the body with `TEncoding.UTF8`.** Create the `TStringStream` without
it and the Persian text goes out in the default Windows codepage, so the
message arrives as question marks.

**Recipient numbers carry no leading zero.** Use `9121112222`, or
`989121112222` with the country code. A number that does not start with `9` or
`989` returns error code `13`.

**Send a unique `UserTraceId` per recipient.** After a timeout it is the only
way to learn whether the message was registered.

## Key safety

The key is a secret. It does not belong in a code repository, in browser
JavaScript, or in a mobile app bundle. It belongs in an environment variable,
which is where every example here reads it from.

If a key leaks, issue a new one from the panel. A deleted key never comes back.

## Layout

| Path | What it holds |
|---|---|
| `examples/v3/` | One self-contained example per operation, using `THTTPClient` |
| `examples/v3-indy/` | The same with `TIdHTTP`, for older projects |
| `testing/` | The Linux build harness, and what it does and does not prove |
| `.env.example` | The environment variables the examples read |

The `v3` in the path is deliberate. A new service version means a new
`examples/v<n>/`, with the existing folder left alone.

## Documentation and support

The full guide to the web service is at
[docs.payam-resan.com](https://docs.payam-resan.com), and the machine-readable
OpenAPI description is in
[sms-webservice-spec](https://github.com/Mojeshahr/sms-webservice-spec).

Question or bug? [Open an issue](https://github.com/Mojeshahr/delphi-sms-webservice/issues)
or contact [support](https://payam-resan.com).

## License

Released under the MIT license. Full text in [`LICENSE`](LICENSE).

<br>
<div align="center">
  <sub>
    <img src=".github/assets/logo.svg" width="16" height="16" alt="" align="top">
    &nbsp;<b>Payam Resan SMS Panel - Moje Shahr</b>&nbsp;
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset=".github/assets/mojeshahr-dark.svg">
      <img src=".github/assets/mojeshahr-light.svg" width="16" height="16" alt="" align="top">
    </picture>
  </sub>
  <br>
  <sub>
    <a href="https://payam-resan.com">payam-resan.com</a>
    &nbsp;·&nbsp;
    <a href="https://mojeshahr.ir">mojeshahr.ir</a>
  </sub>
</div>
