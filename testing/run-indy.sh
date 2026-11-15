#!/bin/bash
# Same harness as the modern set, pointed at examples/v3-indy.
set -u
export LANG=C.UTF-8 LC_ALL=C.UTF-8
mkdir -p /tmp/build /tmp/src

fpc -Mdelphi -Fcutf8 -FE/tmp/build -o/tmp/build/stub /stub.pas >/dev/null 2>&1
/tmp/build/stub &
STUB=$!
sleep 3
trap 'kill $STUB 2>/dev/null' EXIT

status=0
for f in examples/v3-indy/*.dpr; do
  name=$(basename "$f")
  sed 's#https://www.payam-resan.com#http://127.0.0.1:8099#' "$f" > "/tmp/src/$name"

  build=$(fpc -Mdelphi -Fcutf8 -Fu/shims -FE/tmp/build -o"/tmp/build/i-${name%.dpr}" "/tmp/src/$name" 2>&1)
  if [ $? -ne 0 ]; then
    echo "BUILD FAILED  $name"
    printf '%s\n' "$build" | grep -E 'Error|Fatal' | head -4 | sed 's/^/        /'
    status=1
    continue
  fi

  out=$(PAYAM_RESAN_API_KEY=123456-XXXXXXXXXXXXXXX PAYAM_RESAN_SENDER=30004040 \
        "/tmp/build/i-${name%.dpr}" 2>&1)
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
exit $status
