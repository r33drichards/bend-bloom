import Base
import ./bloom.bend as Bloom

# Four-byte little-endian keys. Each shard owns a separate filter.
def key(+n: U32) -> List<&2, U32>:
  [(n .&. 255 : U32), ((n >> 8n) .&. 255 : U32), ((n >> 16n) .&. 255 : U32), (n >> 24n : U32)]

def insert(+n: Nat, result: Result<&2, &1, String, Bloom.Filter>, +offset: U32) -> Result<&2, &1, String, Bloom.Filter>:
  match n:
    case 0n: result
    case 1n+p:
      match result:
        case Fail{e}: Fail{e}
        case Done{f}: insert(p, Bloom.put(f, key((offset + U32.from_nat(p) : U32))), offset)

def count(found: Bool) -> U32:
  match found:
    case False{}: 1
    case True{}: 0

def check(+n: Nat, result: Result<&2, &1, String, Bloom.Filter & Bool>, +offset: U32, errors: U32) -> U32:
  match n:
    case 0n:
      match result:
        case Fail{e}: 4294967295
        case Done{(f, found)}: (errors + count(found) : U32)
    case 1n+p:
      match result:
        case Fail{e}: 4294967295
        case Done{(f, found)}:
          check(p, Bloom.mightContain(f, key((offset + U32.from_nat(p) : U32))), offset, (errors + count(found) : U32))

def verify(result: Result<&2, &1, String, Bloom.Filter>, n: Nat, offset: U32) -> U32:
  match result:
    case Fail{e}: 4294967295
    case Done{f}: check(n, Done{(f, True{})}, offset, 0)

def shard(result: Maybe<Bloom.Filter>, +n: Nat, +offset: U32) -> U32:
  match result:
    case None{}: 4294967295
    case Some{f}: verify(insert(n, Done{f}, offset), n, offset)

def run(+fork_depth: Nat, +word_depth: U32, +probes: U32, +items: Nat, +offset: U32) -> U32:
  match fork_depth:
    case 0n: shard(Bloom.create(word_depth, probes), items, offset)
    case 1n+p:
      a b = run(p, word_depth, probes, items, offset) run(p, word_depth, probes, items, (offset + (1 << p) * U32.from_nat(items) : U32))
      (a + b : U32)
