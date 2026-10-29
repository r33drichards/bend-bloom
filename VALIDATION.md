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

## GPU status

The generated GPU workload passed Bend's check-only validation. Actual compilation was attempted with:

```sh
node cli.mjs benchmark --backend gpu --items 16 --fork-depth 1 --iterations 1
```

It exited unsuccessfully with:

```text
bend needs clang 19 (Apple clang 17) or newer to build a GPU program
(found clang 16 as clang)
```

No GPU program executed and **no GPU throughput or saturation result is available**. No compiler or system installation was changed to work around this requirement. CUDA and Linux have not been exercised.

The pinned runtime source was inspected: explicitly requesting a GPU makes `gpu_probe` failure fatal when the program contains a `!` call. The CLI uses `--gpu 256MB`, not the automatic fallback mode. After a suitable compiler/device setup is available, the experimental GPU path still needs execution and correctness validation on that hardware.
