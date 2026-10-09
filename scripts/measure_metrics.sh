#!/bin/bash
set -euo pipefail

# Usage: ./scripts/measure_metrics.sh [num_tests=1]
# All 20 tests can be run, but the default is 1 as the metrics are the same for all tests. 
NUM_TESTS=${1:-1}

# Generate program.hex if it doesn't exist
if [[ ! -f test/program.hex ]]; then
    ./scripts/encode_assembly.sh test/convolution.asm test/program.hex
fi

iverilog -g2012 -s tb -o test/metrics_sim \
    source/core.v source/pc.v source/if_id.v source/decoder.v source/immgen.v \
    source/id_ex.v source/ex_mem.v source/mem_wb.v source/regfile.v \
    source/alu.v source/alu_control.v source/ex_forward_mux.v source/wb_mux.v \
    source/hazard_unit.v source/lsu.v \
    test/source/ram.v test/source/rom.v test/testbench_metrics.v

echo "test  cycles  retired  CPI  mem_reads  mem_writes"

for ((X = 0; X < NUM_TESTS; X++)); do
    OUT=$(vvp test/metrics_sim "+X=$X" | grep "^METRICS")

    C=$(echo "$OUT" | sed -n 's/.*cycles=\([0-9]*\).*/\1/p')
    R=$(echo "$OUT" | sed -n 's/.*retired=\([0-9]*\).*/\1/p')
    MR=$(echo "$OUT" | sed -n 's/.*mem_reads=\([0-9]*\).*/\1/p')
    MW=$(echo "$OUT" | sed -n 's/.*mem_writes=\([0-9]*\).*/\1/p')

    if [[ -z "$C" || -z "$R" || "$R" -eq 0 ]]; then
        echo "Invalid metrics for test $X: $OUT" >&2
        exit 1
    fi

    CPI=$(awk "BEGIN { printf \"%.2f\", $C / $R }")

    echo "$X  $C  $R  $CPI  $MR  $MW"
done
