# Proof scope and Bloom filter mathematics

This is a **partial, compiler-checked proof layer**, not a proof of the entire Bloom filter implementation. There are 30 laws in `LAWS.bend`, all filled by definitions in `PROOF.bend`. The original six are preserved; 24 general laws have been added. The independent BendTT/Lean kernel has not run.

## Audit of the original laws

| Original law | What it establishes |
| --- | --- |
| `empty_hash` | For every U32 seed, hashing the empty list returns that seed. A general base-case theorem. |
| `empty_bytes_valid` | One concrete empty-list validation result. |
| `rejects_non_byte` | One concrete invalid byte, 256, is rejected. Not a universal validation theorem. |
| `rejects_zero_probes` | One concrete configuration with zero probes is rejected. |
| `rejects_excess_allocation` | One concrete excessive depth is rejected. |
| `binary_roundtrip` | The existing fixed binary example returns true. Not a general no-false-negative theorem. |

## New deterministic theorems

Write `a ∨ b` for bitwise OR and `a ∧ b` for bitwise AND. The word lemmas quantify over **every finite word width and all words of that width**. Their proofs induct on width and cover the Boolean constructor cases with symbolic tails; they do not enumerate U32 values or test samples.

| Laws | Exact scope |
| --- | --- |
| `word_or_idem`, `word_add_idem` | `a ∨ a = a`; `(a ∨ b) ∨ b = a ∨ b`. |
| `word_keep_left`, `word_keep_right` | `(a ∨ b) ∧ a = a`; `(a ∨ b) ∧ b = b`. Existing and newly set bits are retained. |
| `word_or_comm`, `word_or_assoc` | OR is commutative and associative. |
| `word_mask_grows` | `(a ∨ b) ∧ c = (a ∧ c) ∨ (b ∧ c)`. |
| `word_and_zero` | `a ∧ 0 = 0` at every width. |
| `set_idempotent`, `preserves_old_bits`, `contains_new_bits` | The corresponding equations for the exact U32 operations used in `bits.bend`. |
| `union_commutative`, `union_associative`, `union_idempotent` | The algebra of **one U32 word's OR**. These names do not assert a full-filter union API. |
| `inserted_mask_hit` | For any U32 word and nonzero mask, the exact query word predicate reports the mask present after OR insertion. Nonzero is an explicit premise. |
| `position_mask_nonzero` | For every U32 position, the implementation's `1 << (position & 31)` mask is nonzero. All 32 low-bit combinations are covered, with arbitrary upper bits. |
| `single_word_read_after_set` | The actual `Bloom.set_bit` followed by `Bloom.get_bit`, for any U32 word and position on an `ALeaf` array, returns the updated array and `True`. No nonzero premise is needed. |
| `single_word_set_idempotent` | Setting the same position twice in an arbitrary single-word array equals setting it once. |
| `single_word_one_probe` | Actual `put_loop` and `query_loop` with one probe and a single-word array return `True`, for arbitrary initial contents, mask, hash, and step. |
| `single_probe_valid_key` | For any valid byte list and any initial U32 word, the actual checked insertion/query API bodies find that key in a 32-bit, one-probe filter. Valid byte-list membership is an explicit premise; no assumption about hash randomness is needed. |

`bits.bend` is not a separate model disconnected from execution: `bloom.bend` calls its `add`, `hit`, and `position_mask` functions in the array write/read paths. They factor the original operations without changing their definitions. `proof-observers.bend` is proof-only plumbing that discards the affine filter after observing the checked API result. It calls `put_checked` and `query_checked` with the same validation result used by the public wrappers.

The single-probe theorem permits arbitrary pre-existing word contents. It is still restricted to the valid configuration `word_depth = 0`, `probes = 1`; it does not establish the property for every configuration.

## General array refinement progress

Four additional structural theorems quantify over every array shape and arbitrary traversal parameters:

- `array_size_spec`: the actual Base size operation returns the original array and the model size.
- `array_read_spec`: the actual Base traversal returns the original array and the model-selected word.
- `array_swap_spec`: the actual Base traversal returns the model-updated array and the previous selected word.
- `model_read_after_write`: reading the same path after a model write returns the written word.

These relate `array-model.bend` directly to the Base operations used by the program. They are general tree inductions, not fixed-size examples. Composition through the public index-normalizing wrappers, shape preservation, and multiple Bloom probes is still in progress. They do not yet extend the whole-filter no-false-negative theorem beyond the stated special case.

## What remains unproved

- General array read-after-write for multiword trees, followed by an induction over all probe counts and insertion histories.
- Consequently, whole-filter no-false-negatives, whole-filter idempotence, and whole-filter membership monotonicity for every accepted configuration. Existing tests and the algorithmic argument remain evidence, not universal proofs.
- Compatible full-filter union: word OR has proved algebraic properties, but there is no array-wise union implementation or compatibility checker. A future union would require equal shape/size, probe count, hash scheme/seeds, and key encoding; word algebra alone does not prove those conditions.
- Universal byte/configuration-validation correctness, hash quality, probability bounds, the floating-point sizing calculation, or the accuracy of hardware budgets.
- Native C, JavaScript, Metal, or CUDA code generation and runtime correctness. The source-level proofs do not verify these backends.

No open claims pretending to cover these gaps are added. The public API is unchanged.

## Probability formulas and their assumptions

The [Wikipedia Bloom filter article](https://en.wikipedia.org/wiki/Bloom_filter#Probability_of_false_positives) distinguishes deterministic membership behavior from a probabilistic model. Its familiar sizing equations are approximations, including assumptions about hashing and rounding. They must not be installed as unconditional equalities about this program.

Under an ideal model with `m` bit positions, `n` inserted keys, and `k` independent uniform draws per key, a particular bit remains clear with probability

```
q = (1 - 1/m)^(k*n).
```

For finite `m`, different bits' occupancy events are dependent. If `S` is the number of occupied bits and a new absent key has independent uniform query draws, the exact model expression is

```
FPR = E[(S/m)^k],
```

not generally `(E[S]/m)^k`. This distinction is developed by [Christensen, Roginsky, and Jimeno (2010)](https://cse.usf.edu/~kchriste/energy/ipl10.pdf), who give a finite balls-and-bins analysis. It matters particularly for small filters. This is a statement about that random model, not about arbitrary deterministic hashes or adversarial keys.

The CLI uses the common approximation

```
p ≈ (1 - exp(-k*n/m))^k
k_continuous ≈ (m/n) * ln(2)
m_continuous ≈ -n * ln(p) / ln(2)^2.
```

It then checks supported power-of-two sizes and integer probe counts using that approximation. The numeric tests verify the implementation of this selection rule; they do not prove that the observed false-positive rate meets the requested target. No real-number calculus, probability space, occupancy distribution, or floating-point error proof has been formalized in Bend here.

The implementation uses two deterministic FNV-derived hashes and an odd-step double-hash sequence over a power-of-two table. [Kirsch and Mitzenmacher (2008)](https://www.eecs.harvard.edu/~michaelm/postscripts/rsa2008.pdf) analyze double hashing and asymptotic false-positive behavior under specified random-hash models. Their result does not certify the randomness of these particular seeded hashes, or make this finite implementation satisfy a distribution-free FPR bound. We have not proved such assumptions.

The related occupancy estimate `n_est ≈ -(m/k) ln(1 - S/m)` also depends on a model; saturation makes it singular. The project does not expose an exact distinct-key counter, and no counting theorem is claimed. A saturated filter can return true for every absent key, so an unconditional target-FPR guarantee would be false.

## Checker and trust boundary

The pinned compiler is Bend 2.0.39, source tag `a3efe8a3801f423827424227172eed9802c5e6cb`. The [pinned guide](https://github.com/bendlang/bend/blob/v2.0.39/guide/GUIDE.md), [elaborator](https://github.com/bendlang/bend/blob/v2.0.39/bend2/safe.ts), and [BendTT kernel](https://github.com/bendlang/bend/blob/v2.0.39/bend2/bendtt.lean) were inspected.

The proofs use constructor cases, decreasing structural recursion, reflexivity, and Base's equality congruence/transitivity. The new project code contains no `@unsafe`, foreign proof implementation, admitted proof hole, or open law. Conditional laws carry their assumptions explicitly; they do not manufacture witnesses for them.

`bend PROOF.bend` reports `ALL PROOFS CHECK`. The compiler also prints `Use --verdict for mathematical validity.` This result trusts Bend's parser/checker, equality normalization, and the referenced Base definitions.

`bend PROOF.bend -o .build/PROOF.bendtt` successfully emits the elaboration. Export alone is **not** a kernel verdict. In this release, `--verdict` separately checks the elaborated book using a kernel built with Lean 4.34.0 (or a supplied built kernel). No compatible Lean or cached kernel was found in the inspected installation paths. No toolchain was installed, and no successful independent-kernel verification is claimed.

The kernel source includes soundness, termination, empty-type, and equality-adequacy statements/proofs for its theory. Reading these or exporting a book does not replace running the kernel on this project's book. The elaboration, equality's intended interpretation, and backend correspondence remain things a reviewer must assess even after a kernel run.

## Reproduce and challenge the proofs

```sh
.tools/bend/bin/bend PROOF.bend
npm test
.tools/bend/bin/bend PROOF.bend -o .build/PROOF.bendtt
# Only with an installed compatible independent kernel/toolchain:
.tools/bend/bin/bend PROOF.bend --verdict
```

The regression suite checks four deliberate mutations in temporary copies: XOR instead of OR, a zero position mask, discarded insertion, and queries always returning false. Each is rejected by the proof gate. The original files are never mutated by these tests. This demonstrates that the gate is connected to the tested implementation paths; it does not extend the scope of the laws.

Publication of this accurately labeled partial proof feature was explicitly approved. Independent kernel verification and general-proof composition remain ongoing; only actual successful results are recorded.
