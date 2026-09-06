# How these examples are tested, and what that is worth

بیشتر مخزن‌های این سازمان با ابزار خود زبان آزموده می‌شوند. دلفی نمی‌تواند،
چون کامپایلرش فقط روی ویندوز و تجاری است. این پوشه توضیح می‌دهد به‌جایش چه
کاری انجام می‌شود و چه چیزی را ثابت می‌کند.

This folder is written in English below because it is about the build harness,
not about using the service. The Persian documentation is in the two READMEs.

## The idea

Free Pascal understands Delphi syntax in `-Mdelphi` mode, but it does not ship
Delphi's RTL. The units the examples import, `System.Net.HttpClient`,
`System.JSON`, `System.NetEncoding` and Indy's `IdHTTP`, do not exist there.

So `fpc-shims/` provides units with **those exact names**, implementing the
subset the examples use, on top of Free Pascal's own `fphttpclient` and
`fpjson`. The example files themselves are compiled **unchanged**. The file you
hand to RAD Studio is the file that is compiled and run here.

## What is checked

| | |
|---|---|
| Every file compiles | 22 of 22, both sets |
| Every file runs against a stub that answers like the service | 22 of 22 |
| Every file stops on a `200` carrying `Success: false` | 22 of 22, exit code 1 |
| Request bodies | Persian intact, nested arrays real, numbers not strings |
| `Send` query string | percent-encoded exactly once |

The stub is `stub.pas`, a small HTTP server that answers each method with the
shape the real service returns, and logs what it received.

## What is not checked, and why it matters

The stand-in units were written from Embarcadero's published signatures. If a
signature was read wrongly, the same mistake sits in both the stand-in and the
example, the test passes, and real Delphi still fails.

So this harness proves syntax, structure, and that the calls are made with the
right names, arity and types. It does not prove Embarcadero's implementation
behaves identically. **One real build on RAD Studio is still worth doing**, and
the README asks readers to report what they find. That request is genuine.

To keep the stand-ins honest, Delphi's oddities are preserved rather than
smoothed over. `THTTPClient.Create` is declared as a `class function`, not a
constructor, because that is what Delphi declares. An example written against a
constructor would compile here and break there.

## Four real defects this harness caught

It is worth recording that this was not a formality.

1. A function called in the stand-in that did not exist at all.
2. Persian text in the `Send` query string was percent-encoded twice, producing
   `%C3%9A%C2%A9` where `%DA%A9` was meant.
3. `Success` arrived as `True` from `fpjson` where Delphi returns `true`. The
   examples now compare with `SameText`, which is better Delphi code regardless.
4. `152340.5` came back as `1.5234050000000000E+005`, because `fpjson` renders
   every number through a float.

## Running it

Everything happens in a container, so nothing has to be installed on the host.

```bash
docker build -t fpc-check - <<'DOCKER'
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends fp-compiler fp-units-rtl fp-units-fcl \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /w
DOCKER

docker run --rm \
  -v "$PWD:/w:ro" -v "$PWD/testing/fpc-shims:/shims:ro" \
  -w /w fpc-check bash testing/run.sh
```

`-Fcutf8` is not optional: without it the compiler reads the Persian string
literals in the wrong encoding.

## The one artefact to ignore

In the container, Persian string **literals** passed straight to `Writeln` print
as question marks, while the identical text arriving from the response prints
correctly. That is Free Pascal's console handling with no locale installed, not
a defect in the examples. Values from the response are the ones that matter, and
they are verified byte for byte.
