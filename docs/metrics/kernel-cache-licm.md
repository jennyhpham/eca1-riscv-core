# Optimization: kernel register caching + loop-invariant hoisting (+ 2x2 window unroll)

Program-level optimization of `test/convolution_optmised.asm` (branch
`optimisation-kernel-cache`). Core RTL unchanged.

| metric | baseline | optimized | change |
|---|---|---|---|
| cycles | 12,512 | 3,092 | **4.05x faster** |
| retired | 10,202 | 2,718 | 3.75x fewer |
| CPI | 1.23 | 1.14 | -0.09 |
| mem_reads | 968 | 488 | -480 (-49.6%) |
| mem_writes | 121 | 121 | unchanged |

Verified correct: 20/20 convolution tests pass (`./scripts/run_all.sh`).

## What was done

1. **Kernel register caching** — the 4 kernel values are loaded into `s8..s11`
   once in the prologue (4 `lw` total) instead of re-computing the kernel
   address and re-loading on every MAC (was 484 `lw`). This alone removes
   480 memory reads and their load-use stalls.
2. **Loop-invariant hoisting (LICM)** — computations whose operands do not
   change inside a loop were moved out:
   - constants 13 / 11 -> `t4` / `t5`, computed once (was re-materialized
     484x / 121x inside the loops);
   - `i*13` (input row base) and `i*11` (output row base) -> computed once
     per `i` in `for_i_loop` (was a `mul`+`add` per access);
   - loop bounds kept in registers, branches compare against registers.
3. **2x2 window unroll** — the `ki`/`kj` loops are replaced by 4 straight-line
   MACs using the 4 cached kernel registers. This is *required* by register
   caching (RISC-V cannot index registers dynamically) and removes all
   inner-loop counter/branch overhead. Loop-unrolling at the `j` level
   (teammate's task) composes on top of this.

## Observations

- **mem_reads 968 -> 488**: exactly the 484 kernel loads removed
  (484 input loads + 4 kernel loads remain). mem_writes unchanged (121 `sw`),
  as expected.
- **retired 10,202 -> 2,718**: per-pixel body shrank from ~84 instructions
  (18-instr inner body x4 + loop overhead) to 22; the rest of the reduction
  is hoisting + unrolled loop overhead.
- **CPI 1.23 -> 1.14**: fewer loads also means fewer load-use stalls and fewer
  taken branches (branch flushes) per pixel; remaining CPI excess is now
  dominated by the 488 remaining load-use stalls and the 2 back-branches
  per pixel.
- **cycles 12,512 -> 3,092** (4.05x): slightly better than the retired
  reduction because stall cycles shrink proportionally more than retired
  instructions (loads stall; ALU ops do not).

## Core limitation discovered while debugging

`source/alu_control.v` decoded I-type arithmetic (`addi`) through the R-type
`funct7` check. I-type instructions have no funct7 field: instruction bits
[31:25] are immediate bits [11:5]. For `addi` with an immediate in 32..63
(`imm[11:5] == 7'b0000001`) the decoder matched MUL's funct7 pattern, so the
ALU multiplied instead of adding. The original program never used such an
immediate; the first optimized version used `addi t3, t3, 52` (+52 = one row
down in the input matrix), which silently computed `t3 * 52` and corrupted
every output. Diagnosed via VCD waveform trace (regfile write values + store
addresses).

Software workaround used here: build 52 with `slli t6, t4, 2` in the prologue
and use R-type `add t3, t3, t6` in the loop.

RTL fix applied (decoder.v + alu_control.v): I-type arithmetic now uses a
dedicated ALUOp code (`2'b11`) so funct7-style decoding never applies to it;
the I-type operation is selected by funct3 alone (`addi` -> ADD, `slli` ->
SLL). Verified: original + optimized convolution programs 20/20, directed
addi/slli checks pass, Yosys synthesizability unchanged.
