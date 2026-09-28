# ECA1 — Pipelined RISC-V Core 

A pipelined RISC-V (RV32IM subset) processor core in Verilog that can execute  a 2D convolution program (13×13 matrix × 2×2 kernel → 11×11 output).

## Quickstart (devcontainer)
How to setup devcontainer can be found at: https://code.visualstudio.com/docs/devcontainers/containers


1. Open this folder in VS Code → *Reopen in Container* (Docker Desktop must be running).
2. Inside the container, from the repo root:

```bash
./scripts/run_all.sh          # build + run all 20 tests + diff against expected
./scripts/check_synthesizabililty.sh CustomCore   # Yosys synthesizability check
```

The first run of `run_all.sh` auto-encodes `test/convolution.asm` into `test/program.hex`.

## Repository layout

```
source/            
scripts/           Provided scripts 
                   + ours (run_all.sh).
test/              
test/input/        20 fixed-seed test cases (generator.py 20 --seed 42). Committed.
test/output/       Committed
```
## Running a single test

```bash
./scripts/build.sh
vvp convolution_testbench +X=0            # run test 0
diff test_result.out test/output/test0.out
```

`test_result.out` and `wave.vcd` are written to the repo root. Open `wave.vcd` in WaveTrace
(VS Code extension) for waveforms.

## Running tests

- **Standard command (use this only when the full core is implemented):**

  ```bash
  ./scripts/run_all.sh
  ```
- **While the core is still empty/partial:** `RUN_ALL_TIMEOUT=3 ./scripts/run_all.sh`
  for a quick check (~1 min) 
- Expected results with the incomplete core: `20/20 tests failed`, all `TIMEOUT`.

## Branch strategy

- `main` — optimized core 
- `baseline` — unoptimized pipelined core.
- `feature/*` - for example features/program-counter, features/alu, or features/pipeline-registers before being merged into main through a pull request.


## Test generation

The committed test set is reproducible:

```bash
cd test && python3 generator.py 20 --seed 42
```

Tests can be regenerated locally while developing. However, new test sets should NOT be pushed or committed.

GitHub Actions uses the committed test/input/ and test/output/ files as the regression tests. If a different set it push, CI will run against those and test results may be incorrect.