# bend-bloom

A byte-oriented Bloom filter in **Bend 2.0.39**, with a native CPU benchmark and an experimental, strict GPU mode. The core is Bend; Node.js supplies the command-line wrapper, hardware discovery, and test harness. There are no npm dependencies.

A negative lookup means the bytes were not inserted. A positive lookup means they **might** have been inserted. The filter retains bits, not original data. It cannot recover keys or delete them.

## Install and try

Requirements: macOS or Linux, Node.js 20+, curl, tar, a SHA-256 tool, and clang for native builds. GPU builds require clang 19+ (Apple clang 17+) and a supported Metal or CUDA environment. The installer downloads the official release into this checkout and verifies a pinned checksum; it does not edit your shell or credentials.

```sh
sh scripts/install-bend.sh
npm test
.tools/bend/bin/bend example.bend
node cli.mjs stats
node cli.mjs benchmark --backend cpu --word-depth 8 --probes 5 \
  --items 1024 --fork-depth 4 --threads 8
node cli.mjs benchmark --backend gpu --word-depth 5 --probes 5 \
  --items 128 --fork-depth 7
```

`BEND=/absolute/path/to/bend` selects an existing compiler. Scripts reject versions other than 2.0.39. `bend-version` records the pin; the official source tag resolves to `a3efe8a3801f423827424227172eed9802c5e6cb`. Bend 1/HVM code is incompatible with this project. [Official release](https://github.com/bendlang/bend/releases/tag/v2.0.39), [language guide](https://github.com/bendlang/bend/blob/v2.0.39/guide/GUIDE.md). [bend2.dev](https://bend2.dev) is a useful unofficial guide.

## Bend API

Import `./bloom.bend as Bloom`. Treat `Filter` constructors and helper functions as internal; Bend currently exports module definitions. Construct filters through `create` and retain the returned filter after every operation.

| Call | Result |
| --- | --- |
| `create(word_depth, probes)` | `Maybe<Filter>`; `None{}` for invalid settings |
| `put(filter, bytes)` | `Result<&2, &1, String, Filter>` |
| `mightContain(filter, bytes)` | `Result<&2, &1, String, Filter & Bool>` |

Inputs are `List<&2, U32>` whose elements must be in 0–255. Both operations validate the input and return `Fail{"byte outside 0..255"}` for larger values. An invalid operation consumes the filter; validate with `valid_bytes` first if you need to preserve it on failure. Bend's `U32` type excludes negative and fractional values. JavaScript callers of compiler-generated modules must enforce that type boundary themselves.

Empty bytes, embedded NULs, and non-UTF-8 sequences are valid. Encode text as UTF-8 consistently before insertion and lookup. Integers, records, and other values need a stable encoding, including byte order, field boundaries, and any normalization. Different encodings are different keys. The core does not interpret text.

See [example.bend](example.bend) for a complete Bend program that inserts `[0, 255, 128, 0]`, queries it, and returns `True{}`. The affine array has one owner: `put` returns the updated filter, and `mightContain` returns the filter alongside the answer. Do not reuse stale JavaScript aliases to that array.

## Sizing, hashing, and storage

`word_depth` ranges from 0 to 15. It allocates `2^word_depth` U32 words, for `m = 32 × 2^word_depth` bits. `probes` ranges from 1 to 32. Invalid settings are rejected before allocation. Logical packed payload ranges from 4 bytes to 128 KiB; Bend's array/runtime representation adds overhead.

For an anticipated `n` distinct keys and target false-positive probability `p`, estimate `m = -n ln(p)/(ln 2)^2`, round up to a supported power-of-two bit count, then choose `k ≈ (m/n) ln 2`, bounded to 1–32. For 1,000 keys at roughly 1%, use depth 9 (16,384 bits) and 11 probes. This is an estimate under idealized hashing, not a guarantee. This first API exposes explicit size and probe count; it does not yet provide `create(expectedItems, fpp)`.

Each key is hashed with two FNV-1a accumulators (seeds 2166136261 and 3339675911, multiplier 16777619), followed by the Murmur3 32-bit avalanche finalizer. These are noncryptographic operations modulo 2^32. The second hash is made odd. Probe `i` uses `(h1 + i*h2) & (m-1)`, starting at zero. An odd step visits distinct positions over the power-of-two table until it wraps. Word index is `position >> 5`; the bit is `1 << (position & 31)`.

Insertion only ORs bits; queries reproduce the same positions and require all bits to be set. Thus valid insertions cannot remove evidence of earlier insertions. Duplicate insertions leave storage unchanged. Saturation raises false positives and can make every query positive. This reasoning assumes the same configuration/encoding and no mutation outside the API. There is no deletion, persistence, merge API, automatic resizing, adversarial-key resistance, or compatibility with another implementation's serialized format.

## CLI and CPU/GPU exploration

`stats` reports CPU, memory, compiler, and available graphics information. Failed probes appear as unavailable with their reason. Hardware discovery does not establish that a Bend GPU binary can run. `CC` and `SDKROOT` can select an already-installed compiler and SDK per process; `stats` reports these selections. See the validation record for the verified clang 21/SDK 15.2 combination on this machine.

`benchmark`, `start`, and `run` are aliases. Use `node cli.mjs --help` for bounds. `--fork-depth d` creates `2^d` independent filter shards with balanced parallel calls. Each shard inserts its keys sequentially, then queries all of them. No array is written by two tasks. This avoids lost bit updates without assuming shared atomic OR support. It benchmarks a batch of independent filters, **not one shared global filter**. More shards expose more parallelism; they do not prove GPU saturation.

CPU mode explicitly disables GPU execution. GPU mode uses Bend's `!` call and passes `--gpu 512MB`. In the pinned runtime, an explicit GPU request makes an unavailable device/backend an error. It cannot silently fall back. The generated program must contain the GPU call; compilation and runtime errors fail the command. CUDA execution has not been tested here.

Bounds limit a run to 262,144 keys per iteration, 8 MiB of logical bit payload across shards, 1–5 warmups, 1–10 measured iterations, 32 CPU workers, and a 120-second timeout per subprocess. The GPU heap is capped at 512 MiB; 256 MiB was below Bend’s fixed runtime allocation requirement. Actual host allocations exceed packed payload. Run one benchmark at a time per checkout because `.build/benchmark` is shared.

Output separates build time, process wall time (including warmup/startup), and measured workload wall times. Workload timing has millisecond resolution and includes key generation, allocation, insertion, all lookups, reduction, and one diagnostic print. GPU timing would include dispatch and synchronization. Isolated kernel time, occupancy, power, and utilization are not measured. Throughput counts insertions plus lookups, and is null for samples below timer resolution. Warmups run inside the same process before measured iterations. Sweep shard count and work per shard on a working GPU, checking correctness and timing; do not infer saturation from throughput alone.

The official [shader guide](https://github.com/bendlang/bend/blob/v2.0.39/guide/SHADERS.md) explains why balanced work and enough independent tasks matter. Pointer-heavy Bloom filter work may be slower on a GPU; this project makes no speedup claim.

## Validation

Run `npm test`. The harness compiles the Bend module to JavaScript, exercises its exported functions, checks the proof file, and compiles/runs the native example. The test oracle uses an independent unpacked bit array and checks both packed storage and queries. The native benchmark additionally checks every inserted key after each shard is fully populated.

[VALIDATION.md](VALIDATION.md) records the actual environment, results, and GPU recovery. Tests include empty bytes, NUL, non-UTF-8, UTF-8 text bytes, all 256 byte values, deterministic random binary keys, duplicates, invalid configuration/bytes, and an intentionally saturated filter.

`LAWS.bend` defines six compiler-checked laws. One is symbolic (empty input preserves any hash seed); the rest are concrete validation/round-trip regressions. **The general no-false-negative property is tested and explained, not formally proved for every filter and byte sequence.** `bend PROOF.bend` passes. The optional independent `--verdict`/Lean kernel check was not run. No `@unsafe`, foreign code, or proof holes appear in the core.

## References and networking

API naming follows [Guava's BloomFilter](https://guava.dev/releases/33.4.0-jre/api/docs/com/google/common/hash/BloomFilter.html): `create`, `put`, and `mightContain`. Guava also offers expected-insertion/false-positive sizing. [bits-and-blooms/bloom](https://github.com/bits-and-blooms/bloom) is a compact Go reference with byte inputs, `Add`, `Test`, and `NewWithEstimates`. These are API/design references; their implementation code was not copied. Our ownership and return conventions differ.

Redis's [BF.RESERVE](https://redis.io/docs/latest/commands/bf.reserve/), [BF.ADD](https://redis.io/docs/latest/commands/bf.add/), and [BF.EXISTS](https://redis.io/docs/latest/commands/bf.exists/) are useful future network-API references. This repository does not run a server.

Bend 2.0.39 has TCP and UDP effects, including byte operations, in its [standard library](https://github.com/bendlang/bend/blob/v2.0.39/bend2/base.bend). Official demos implement [plain HTTP fetch](https://github.com/bendlang/bend/blob/v2.0.39/demos/io_http_fetch/main.bend) and an [HTTP server](https://github.com/bendlang/bend/blob/v2.0.39/demos/io_http_server/main.bend) on TCP. The fetch demo states that the TCP kit has no DNS. Inspection of this version's standard library and effects found no built-in TLS/HTTPS API or general HTTP library. The demos do not establish production HTTP support. No networking or deployment was added to this project.
