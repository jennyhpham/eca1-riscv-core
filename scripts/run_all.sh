#!/bin/bash
set -euo pipefail

NUM_TESTS=${1:-20}

# Must be run from the project root
if [[ ! -f test/testbench.v ]]; then
  echo "ERROR: run from the repo root" >&2
  exit 2
fi

# Encode the convolution program if program.hex is missing
if [[ ! -f test/program.hex ]]; then
  echo "program.hex missing, encoding from test/convolution.asm"
  ./scripts/encode_assembly.sh test/convolution.asm test/program.hex
fi

./scripts/build.sh

TIMEOUT_SECONDS=${RUN_ALL_TIMEOUT:-60}

FAILED=0
for ((X = 0; X < NUM_TESTS; X++)); do
  RC=0
  timeout "$TIMEOUT_SECONDS" vvp convolution_testbench "+X=$X" > /dev/null || RC=$?
  if [[ $RC -eq 124 ]]; then
    echo "TEST $X: TIMEOUT after ${TIMEOUT_SECONDS}s"
    FAILED=$((FAILED + 1))
    continue
  elif [[ $RC -ne 0 ]]; then
    echo "TEST $X: sim crashed (exit $RC)"
    FAILED=$((FAILED + 1))
    continue
  fi
  if diff -q test_result.out "test/output/test${X}.out" > /dev/null; then
    echo "TEST $X: PASS"
  else
    echo "TEST $X: FAIL"
    FAILED=$((FAILED + 1))
  fi
done

echo "----"
echo "${FAILED}/${NUM_TESTS} tests failed (per-test timeout: ${TIMEOUT_SECONDS}s, override with RUN_ALL_TIMEOUT)"
exit $FAILED
