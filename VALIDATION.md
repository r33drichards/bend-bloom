# Validation record

Validated locally on 2026-10-29. These are observed results, not performance promises.

## Toolchain and hardware

- Official Bend release: 2.0.39, tag commit `a3efe8a3801f423827424227172eed9802c5e6cb`.
- The project installer successfully downloaded and verified the official Darwin arm64 archive against SHA-256 `d4aaef68de545727429ce83b9e88ff3273bf068df599e3542e446755b5f3d83a`.
- Darwin arm64; Apple M3; 8 logical CPU cores; 16 GiB reported memory.
- Graphics discovery: Apple M3, 10 GPU cores, Metal supported.
- Native compiler: Apple clang 16.0.0.

## Correctness

`npm test` passed:

- `PROOF.bend`: ALL PROOFS CHECK for six laws. The independent Lean-backed `--verdict` check was not run.
- 1,836 inserted-key checks across six size/probe configurations: zero false negatives.
- 6,000 absent/random-key queries agreed with an independent unpacked-bit-array oracle. Packed word contents also agreed bit for bit.
- Empty filters returned false; duplicate insertion preserved the packed words.
- Binary cases: empty bytes, embedded NUL, non-UTF-8, UTF-8-encoded text, all 256 byte values, and deterministic random byte sequences.
- Invalid byte values and size/probe configurations were rejected; maximum accepted core configuration was exercised.
- An intentionally saturated 32-bit filter returned a false positive, as expected.
- FNV-1a known vector: `hello` gives `0x4f9f2cab` with the standard seed.
- Native-compiled binary example returned `True{}`.
- Native CPU batch test inserted and checked 1,024 keys per iteration, after all keys had been inserted, with zero false negatives.
- CLI invalid-backend, input-range, and combined resource-limit checks passed.

A separate deterministic sample inserted 1,000 four-byte little-endian integers into a 16,384-bit filter with 11 probes, then checked integers 1,000 through 10,999. It produced **4 false positives out of 10,000 absent keys (0.04%)**. This sample is not an upper bound on false-positive probability.

## CPU benchmark

Command:

```sh
node cli.mjs benchmark --items 1024 --fork-depth 4 --word-depth 8 --iterations 3
```

Observed: 16 shards, 8,192 bits/shard, five probes, 8 CPU workers; 16,384 inserted keys and 16,384 lookups per iteration. One warmup preceded three samples of **41, 40, and 43 ms**. Aggregate throughput was **792,774 operations/second**, counting both insertion and lookup. Build took about 373 ms; total process wall time was about 166 ms. All checks reported zero false negatives.

The workload includes allocation, key generation, insertion, queries, reduction, and diagnostic printing. These are coarse millisecond wall timings, not isolated hash, kernel, or GPU-saturation measurements. They can vary substantially with system load.

## GPU recovery and verification

A bounded follow-up found installed LLVM clang 19 and 21 toolchains in the Nix store. No Apple clang 17+ or full Xcode installation was found. The successful combination was **LLVM clang 21.1.8 plus the already-installed macOS 15.2 SDK**. Selection was per-process; no software, licenses, global developer directory, credentials, or shell configuration changed.

Recovery steps and outcomes:

1. Default Apple clang 16 refused GPU compilation because Bend requires LLVM clang 19+/Apple clang 17+.
2. The installed clang 19 wrapper used an older SDK lacking `MTLCompileOptions.mathMode`; raw clang 19 with SDK 15.2 failed in SDK module imports.
3. Raw clang 21.1.8 with SDK 15.2 compiled successfully. A project-local module cache avoided writing the user-wide compiler cache.
4. Sandboxed execution reported no usable Metal GPU. Authorized execution with hardware access reached Metal.
5. The original 256 MiB cap failed before the workload: `the GPU span is under the rings, stacks and a page per lane`. The runtime's fixed rings/stacks already exceed that cap. The CLI cap was corrected to **512 MiB**; it remains explicit and bounded.
6. A two-shard, 16-key-per-shard smoke test completed on GPU with zero errors. The full bounded workload below also passed. No CPU fallback was enabled.

Reproduction on this machine (the Nix-store path is machine-specific):

```sh
mkdir -p .build/clang-cache
SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.2.sdk \
CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache" \
CC=/nix/store/q87hv65x5q7fclsshw34i7i1nky8ml7x-clang-21.1.8/bin/clang \
node cli.mjs benchmark --backend gpu --items 1024 --fork-depth 4 \
  --word-depth 8 --iterations 3
```

Use the same command with `--backend cpu` for the CPU workload. GPU execution requires host access to Metal. The CLI passes `--gpu 512MB`; in the pinned runtime an explicit request makes an unavailable backend fatal.

### Recovery measurements

Both used Bend 2.0.39, LLVM clang 21.1.8, 16 independent shards, 8,192 bits/shard, five probes, 1,024 four-byte integer keys per shard, eight CPU workers, one warmup, and three measured iterations. Each iteration performs 16,384 insertions and 16,384 lookups. Every inserted key was checked after its shard was populated, and every warmup/measured iteration reported zero false negatives.

| Backend | Workload samples (ms) | Insert/query operations per second | Process wall time (ms) | Build (ms) |
| --- | --- | --- | --- | --- |
| CPU | 69, 70, 69 | 472,615 | 280.8 | 833.0 |
| Metal GPU | 527, 474, 454 | 67,563 | 2,457.1 | 2,297.7 |

Raw results are in [validation/cpu-recovery.json](validation/cpu-recovery.json) and [validation/gpu-verified.json](validation/gpu-verified.json). The earlier 792,774 CPU result used Apple clang 16 and a different run; retain its original parameters and timings above rather than treating these samples as interchangeable.

**Timing interpretation:** throughput uses the sum of measured workload wall times, excluding warmup, process startup, and compilation. It includes allocation, key generation, hashing, insertion, all lookups, reduction, and one diagnostic print; GPU samples also include dispatch and synchronization. Thus it measures the whole timed workload, **not kernel-only throughput and not full process end-to-end throughput**. `processWallMs` separately includes warmup and startup. Build time is separate again.

The GPU was slower for this small, pointer-heavy, 16-shard workload. These runs verify execution and correctness, not GPU saturation or a general CPU/GPU speed comparison. There was no occupancy measurement, broad parameter sweep, or interleaved repeated comparison. CUDA and Linux remain untested. The optional independent Lean proof check remains unrun.

After the cap/stats changes, `npm test` passed again. `stats` now reports the compiler selected through `CC` and any `SDKROOT`, so an overridden toolchain is visible.

## Hardware-aware sizing validation

The new `size` command and benchmark `--expected-items`/`--fpp` path were validated with the unchanged Bend 2.0.39 core.

- Independent formula enumeration checked 40 feasible count/error-rate combinations against the selected minimum power-of-two size and optimal integer probe count. Two infeasible combinations were rejected.
- Tests cover a probability boundary that requires the next table size, maximum core size, the 32-probe limit, exact-fit and one-byte-short budgets, per-shard overhead multiplication, invalid/nonfinite/overflowing inputs, and known-zero versus unknown memory.
- Synthetic hardware snapshots exercise unified memory counted once, dedicated GPU headroom, explicit budget overrides, physical limits, and the 512 MiB GPU cap. These tests do not pretend to reserve hardware capacity.
- 3,033 keys inserted into four automatically selected configurations were all found after insertion. A native auto-sized CPU workload also completed with zero false negatives.
- The complete `npm test` suite, including the original tests and proof check, passed after this feature.
- An actual Metal smoke test used the previously verified installed clang 21/SDK 15.2, `--expected-items 16 --fpp .01 --budget-mib 512 --items 16 --fork-depth 1 --iterations 1`. The planner selected 256 bits and 11 probes per shard, with predicted FPR about 0.00045871. Both the warmup and measured iteration checked all 32 inserted keys with zero false negatives. The measured workload was 14 ms; this tiny sample is a correctness check, not a throughput/saturation claim.

The GPU smoke test used an explicit budget and reported unknown GPU memory classification in that process; separate `stats` execution detected the M3 unified-memory GPU. The explicit assumption and free-memory snapshot are preserved in [validation/gpu-sizing.json](validation/gpu-sizing.json). This illustrates why capacity discovery and actual runtime verification are separate.

## Partial proof feature

- Audited all six existing laws and preserved them. Five are concrete regressions; `empty_hash` is a symbolic base-case theorem.
- Added 24 general laws, including structural word algebra, mask nonzeroness, actual single-word read-after-set/idempotence, and no-false-negatives for arbitrary valid byte lists on a one-word, one-probe filter. See PROOFS.md for the exact limits.
- `bend PROOF.bend` and `--check-only` both report ALL PROOFS CHECK for the 30-law set. BendTT export succeeds.
- The full `npm test` suite passes with the factored runtime word operations. Four deliberate mutations (OR-to-XOR, zero mask, discarded insertion, query-always-false) are rejected in temporary copies by the proof gate.
- At this checkpoint no independent BendTT kernel verdict was obtained: Lean 4.34.0 and a cached kernel were absent from inspected locations. No toolchain was installed.
- Whole-filter multiword/multiprobe correctness, full-filter compatible union, and probabilistic FPR bounds remain unproved. Publication of this partial proof feature was explicitly approved; the limits above remain.
