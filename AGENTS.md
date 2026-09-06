# Agent guide

Runnable Delphi examples for the Payam Resan SMS web service. One file per API
method, and every file has to work on its own.

## Rule one: no dependencies

An example runs with a stock Delphi and nothing else. `System.Net.HttpClient`,
`System.JSON` and `System.NetEncoding` are all in the RTL, so there is no
component to install and nothing from GetIt. A reader copies the file into
their project and it builds.

The same rule rules out helpers from this repository. There is no shared client
unit here and there should not be one: a function defined in `utils/` means
nothing to somebody reading the file on the documentation site.

## Rule two: two sets, and they stay in step

`examples/v3/` uses `THTTPClient` from the RTL. `examples/v3-indy/` uses Indy's
`TIdHTTP`, for projects whose network layer already runs on Indy.

Both sets carry the same eleven file names. A change to a method's payload,
field names or output belongs in both files or in neither. The Indy header
comment deliberately points at the main set rather than repeating the whole
explanation, so the long-form description exists once.

Only the HTTP call differs. The JSON building and reading, the `Success` check
and the printed output are identical on purpose.

## Rule three: the file name and the program name differ

The reference page slug is kebab-case, so the file is `send-bulk.dpr`, while
Pascal needs an identifier, so the program is `SendBulk`. The Indy set appends
`Indy` to the program name so the two can sit in one project group without a
clash. The file name is what ties an example to its documentation page and is
never changed to match the identifier.

## Rule four: the examples are the documentation

Each file carries `// docs:start` and `// docs:end`. The region between them is
lifted verbatim into the method's page on docs.payam-resan.com, so it is read by
people who have never seen this repository.

Two consequences:

- **Full-line comments are stripped** when the region is lifted. Anything the
  reader must see has to be code. The `Success` check is an `if`, not a note.
- The file name matches the reference page slug exactly. A path with two
  variants gets two files, the plain name for `POST` and a `-get` suffix for
  `GET`.

The full contract lives in the `handbook` repository, section `docs-site`, file
`code-samples.md`.

## Rule five: check Success, never the status code

The service answers `200` to everything, including a wrong key and an empty
account, so `Answer.StatusCode` proves nothing:

```pascal
if not SameText(Response.GetValue('Success').Value, 'true') then
begin
  Writeln('ناموفق. کد ', Response.GetValue('ErrorCode').Value,
          ': ', Response.GetValue('Error').Value);
  Halt(1);
end;
```

`SameText` rather than `<>` is deliberate. The comparison is against a JSON
boolean rendered as text, and the harness found one implementation returning
`True` where Delphi returns `true`. Case-insensitive costs nothing and removes
a whole class of surprise.

## Rule six: build the body with TEncoding.UTF8

```pascal
Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
```

Leave the encoding off and the Persian text goes out in the default Windows
codepage, so the message arrives as question marks. This is the single most
likely thing to be dropped when someone adapts an example.

## Rule seven: a version is a folder

A new service version means a new `examples/v<n>/`. No file inside an existing
version folder is moved or renamed; older versions still have users.

## Secrets

The key comes from `PAYAM_RESAN_API_KEY` in the environment. No key, no real
phone number and no customer name goes into a file here, not even a dead one.
Example numbers are `9121112222` upward and the example key is
`123456-XXXXXXXXXXXXXXX`.

## Layout

| Path | What it holds |
|---|---|
| `examples/v3/` | one self-contained file per operation, using `THTTPClient` |
| `examples/v3-indy/` | the same with `TIdHTTP` |
| `testing/` | the Linux build harness, and what it does and does not prove |
| `.env.example` | the environment variables the examples read |

## Before every commit

```bash
docker run --rm -v "$PWD:/w:ro" -v "$PWD/testing/fpc-shims:/shims:ro" \
  -w /w fpc-check bash testing/run.sh
docker run --rm -v "$PWD:/w:ro" -v "$PWD/testing/fpc-shims:/shims:ro" \
  -w /w fpc-check bash testing/run-indy.sh
docker run --rm -v "$PWD:/w:ro" -v "$PWD/testing/fpc-shims:/shims:ro" \
  -w /w fpc-check bash testing/run-failure.sh
```

Read `testing/README.md` first. That harness is not a real Delphi build, and
the difference matters when judging what a green run means.

Point the examples at `api/V3SandBox/` before running one for real, so no
message goes out.

## Git

Semantic messages, `type(scope): subject`, with no explanatory body and no
attribution trailer. Commits here are authored as Payam Resan.
