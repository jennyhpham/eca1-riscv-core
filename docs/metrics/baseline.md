# Baseline metrics

| metric | value |
|---|---|
| cycles | 12,512 |
| retired | 10,202 |
| CPI | 1.23 |
| mem_reads | 968 |
| mem_writes | 121 |


## Observations (motivation for optimizations)

- **968 memory reads** = 484 MACs × 2 `lw` per MAC — the kernel (4 values) is
  re-loaded from RAM on every MAC. Loading it once into registers removes ~964
  loads and their associated load-use stalls.
- **CPI 1.23** — the excess over 1.0 comes from load-use stalls (1 cycle each,
  ~2 per pixel body) and taken-branch flushes (2 bubbles each, ~968 branch
  executions incl. inner-loop back-branches).
- **10,202 retired instructions** for 484 MAC operations — the loop overhead
  (counter updates + branches + re-hoisted constants) dominates; motivates
  unrolling and loop-invariant hoisting.

