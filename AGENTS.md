# Working on bend-bloom

Use Bend 2.0.39 and read `bend guide` before changing Bend code.
Keep arbitrary bytes as the public input contract; text encoding belongs to callers.
Run `npm test` and `bend PROOF.bend` after core changes. Keep law statements separate from proofs.
Do not claim a general formal proof: the exact scope and remaining gaps are documented in PROOFS.md.
Preserve strict GPU failure behavior, bounded workloads, and single-owner bit storage.
Do not introduce concurrent shared writes without a verified synchronization design.
Update VALIDATION.md with actual results; do not manufacture GPU timings or claim saturation without measurement.
