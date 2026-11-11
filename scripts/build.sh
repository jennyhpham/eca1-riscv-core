#!/bin/bash
set -euo pipefail

# Must be run from the project root.
OUT="./convolution_testbench"

# Core RTL files
CORE_FILES=(
    source/core.v
    source/pc.v
    source/if_id.v
    source/id_ex.v
    source/ex_mem.v
    source/mem_wb.v
    source/alu.v
    source/alu_control.v
    source/decoder.v
    source/ex_forward_mux.v
    source/wb_mux.v
    source/hazard_unit.v
    source/immgen.v
    source/lsu.v
    source/regfile.v
)

# Testbench infrastructure (RAM, ROM) and the convolution testbench
TB_FILES=(
    test/source/ram.v
    test/source/rom.v
    test/testbench.v
)

iverilog -g2012 -s tb -o "$OUT" "${CORE_FILES[@]}" "${TB_FILES[@]}"
echo "Built: $OUT"
