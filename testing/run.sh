#!/bin/bash
# Compile each example against the stand-in units, then run it against a stub
# that answers the way the service does, so the field names each file reads are
# checked and not just that it builds.
set -u
mkdir -p /tmp/build /tmp/src

# The stub is a plain Pascal program too, so the container needs nothing else.
fpc -Mdelphi -Fcutf8 -FE/tmp/build -o/tmp/build/stub /stub.pas >/dev/null 2>&1 || {
  echo "stub failed to build"; fpc -Mdelphi -Fcutf8 /stub.pas 2>&1 | grep -E 'Error|Fatal' | head; exit 1; }

export LANG=C.UTF-8 LC_ALL=C.UTF-8
/tmp/build/stub &
STUB=$!
sleep 3
trap 'kill $STUB 2>/dev/null' EXIT

status=0
for f in examples/v3/*.dpr; do
  name=$(basename "$f")
  sed 's#https://api.sms-webservice.com#http://127.0.0.1:8099#' "$f" > "/tmp/src/$name"

  if ! fpc -Mdelphi -Fcutf8 -Fu/shims -FE/tmp/build -o"/tmp/build/${name%.dpr}" "/tmp/src/$name" >/dev/null 2>&1; then
    echo "BUILD FAILED  $name"; status=1; continue
  fi

  out=$(PAYAM_RESAN_API_KEY=123456-XXXXXXXXXXXXXXX PAYAM_RESAN_SENDER=30004040 \
        "/tmp/build/${name%.dpr}" 2>&1)
  code=$?

  if [ "$code" -eq 0 ]; then
    echo "PASS  $name"
    printf '%s\n' "$out" | sed 's/^/        /'
  else
    echo "FAILED  $name  exit=$code"
    printf '%s\n' "$out" | head -5 | sed 's/^/        /'
    status=1
  fi
done

echo
echo "--- what the stub received ---"
cat /tmp/stub.log 2>/dev/null
exit $status
