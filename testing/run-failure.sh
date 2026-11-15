#!/bin/bash
# The other half of the contract: a 200 answer carrying Success=false must stop
# the example. The method name gets a prefix so the stub has no entry for it and
# answers with a failure envelope.
set -u
export LANG=C.UTF-8 LC_ALL=C.UTF-8
mkdir -p /tmp/build /tmp/fail

fpc -Mdelphi -Fcutf8 -FE/tmp/build -o/tmp/build/stub /stub.pas >/dev/null 2>&1
/tmp/build/stub &
STUB=$!
sleep 3
trap 'kill $STUB 2>/dev/null' EXIT

status=0
for f in examples/v3/*.dpr; do
  name=$(basename "$f")
  sed 's#https://www.payam-resan.com/api/V3/#http://127.0.0.1:8099/api/V3/Unknown#' "$f" > "/tmp/fail/$name"

  fpc -Mdelphi -Fcutf8 -Fu/shims -FE/tmp/build -o"/tmp/build/f-${name%.dpr}" "/tmp/fail/$name" >/dev/null 2>&1

  out=$(PAYAM_RESAN_API_KEY=123456-XXXXXXXXXXXXXXX PAYAM_RESAN_SENDER=30004040 \
        "/tmp/build/f-${name%.dpr}" 2>&1)
  code=$?

  # The message text is checked by its error code rather than its Persian, since
  # the console mangles literals in this image while the values do arrive intact.
  if [ "$code" -eq 1 ] && printf '%s' "$out" | grep -q '404'; then
    echo "PASS  $name  exit=$code"
  else
    echo "FAILED  $name  exit=$code"
    printf '%s\n' "$out" | head -3 | sed 's/^/        /'
    status=1
  fi
done
exit $status
