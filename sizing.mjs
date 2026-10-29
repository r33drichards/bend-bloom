// Planning only: estimates do not reserve memory or guarantee allocation success.
export const MiB = 1024 * 1024;
export const GPU_HEAP_BYTES = 512 * MiB;
const MAX_BITS = 32 * 2 ** 15;
const validBytes = x => Number.isSafeInteger(x) && x > 0;
const knownCapacity = x => Number.isSafeInteger(x) && x >= 0;

export function budgetFor(snapshot, backend, overrideMiB) {
  if (!['cpu', 'gpu'].includes(backend)) throw new Error('backend must be cpu or gpu');
  const free = knownCapacity(snapshot.freeMemoryBytes) ? snapshot.freeMemoryBytes : null;
  const total = validBytes(snapshot.memoryBytes) ? snapshot.memoryBytes : null;
  // Leave at least 75% of reported free RAM to other processes and build/runtime overhead.
  const hostEstimate = free !== null && total !== null ? Math.floor(Math.min(free / 4, total / 8, 1024 * MiB)) : null;
  const gpu = snapshot.gpuMemory || {kind: 'unknown', freeBytes: null};
  let estimate = hostEstimate;
  if (backend === 'gpu') {
    if (gpu.kind === 'unified') estimate = hostEstimate === null ? null : Math.min(hostEstimate, GPU_HEAP_BYTES);
    else if (gpu.kind === 'dedicated' && knownCapacity(gpu.freeBytes) && hostEstimate !== null)
      estimate = Math.floor(Math.min(hostEstimate, gpu.freeBytes / 2, GPU_HEAP_BYTES));
    else estimate = null;
  }
  const override = overrideMiB !== undefined;
  if (override && (!Number.isFinite(overrideMiB) || overrideMiB <= 0 || !Number.isSafeInteger(overrideMiB * MiB)))
    throw new Error('budget-mib must be positive and represent a safe integer number of bytes');
  const requested = override ? overrideMiB * MiB : estimate;
  if (requested === null) throw new Error('Available memory capacity is unknown; supply an explicit --budget-mib to plan under your own budget');
  if (total !== null && requested > total) throw new Error('Requested budget exceeds total host memory');
  if (backend === 'gpu' && gpu.kind === 'dedicated' && validBytes(gpu.totalBytes) && requested > gpu.totalBytes)
    throw new Error('Requested budget exceeds total GPU memory');
  const budgetBytes = backend === 'gpu' ? Math.min(requested, GPU_HEAP_BYTES) : requested;
  return {budgetBytes, requestedBudgetBytes: requested, source: override ? 'explicit override' : 'conservative snapshot estimate',
    hostFreeBytes: free, gpuMemoryKind: gpu.kind, exceedsFreeSnapshot: free !== null && requested > free,
    runtimeReserveBytes: (backend === 'gpu' ? 448 : 64) * MiB,
    note: 'No memory is reserved. Free-memory snapshots can change and omit reclaimable memory or process limits. Default: min(25% host free, 12.5% host total, 1 GiB); dedicated GPU also uses at most 50% device free. GPU is capped at the CLI 512 MiB heap. Unified memory is counted once. Overrides replace the free-memory/headroom policy and may exceed the free snapshot; they remain subject to known total physical memory and the GPU cap. They are user assumptions, not verified available capacity.'};
}

export function predictedFpr(items, bits, probes) {
  // Stable for small exponents; logarithms avoid underflow during selection.
  return Math.exp(probes * Math.log(-Math.expm1(-probes * items / bits)));
}

export function chooseSizing({expectedItems, targetFpr, backend = 'cpu', shards = 1, budget}) {
  if (!Number.isSafeInteger(expectedItems) || expectedItems < 1) throw new Error('expected-items must be a positive safe integer');
  if (!Number.isFinite(targetFpr) || targetFpr <= 0 || targetFpr >= 1) throw new Error('fpp must be finite and strictly between 0 and 1');
  if (!Number.isSafeInteger(shards) || shards < 1 || shards > 16384) throw new Error('shards must be an integer 1..16384');
  if (!['cpu', 'gpu'].includes(backend)) throw new Error('backend must be cpu or gpu');
  if (!budget || !knownCapacity(budget.budgetBytes) || !Number.isSafeInteger(budget.runtimeReserveBytes) || budget.runtimeReserveBytes < 0)
    throw new Error('A valid resource budget is required');
  const idealBits = -expectedItems * Math.log(targetFpr) / Math.LN2 ** 2;
  if (!Number.isFinite(idealBits) || idealBits > MAX_BITS) throw new Error('Requested error rate/count exceeds the core maximum of 1048576 bits per filter');
  const logTarget = Math.log(targetFpr);
  // Scan only 16 supported sizes and all 32 integer probe counts; rounding the
  // continuous optimum alone can miss a target near an integer boundary.
  for (let depth = 0; depth <= 15; depth++) {
    const bits = 32 * 2 ** depth;
    let bestLog = Infinity, probes = 1;
    for (let k = 1; k <= 32; k++) {
      const log = k * Math.log(-Math.expm1(-k * expectedItems / bits));
      if (log < bestLog) { bestLog = log; probes = k; }
    }
    if (bestLog > logTarget) continue;
    const words = bits / 32;
    // Conservative planning model for Bend's array tree and transient work.
    // This is not measured resident memory: reserve + 64 bytes/word + 4 KiB/shard.
    const estimatedBytes = budget.runtimeReserveBytes + shards * (64 * words + 4096);
    if (estimatedBytes > budget.budgetBytes)
      throw new Error(`Insufficient resource budget: estimated ${estimatedBytes} bytes required, ${budget.budgetBytes} available (including runtime reserve and array overhead)`);
    return {expectedItemsPerShard: expectedItems, targetFpr, predictedFpr: Math.exp(bestLog), wordDepth: depth,
      probes, bitsPerShard: bits, packedBytesPerShard: bits / 8, shards,
      totalPackedBytes: shards * bits / 8, estimatedRequiredBytes: estimatedBytes, backend, budget,
      predictionNote: 'Idealized independent/uniform-hash estimate, not a guaranteed observed false-positive rate. expected-items is a caller-supplied expected DISTINCT count per shard; the filter does not count exact distinct keys. Exceeding it can increase false positives. Sizing does not establish GPU usability.'};
  }
  throw new Error('Target cannot be met within the supported bit/probe limits (1048576 bits, 32 probes)');
}
