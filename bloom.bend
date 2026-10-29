import Base

# Public API: create, put, mightContain. Helpers and constructors are internal.
# An affine filter owns its packed words; query returns ownership to the caller.
type Filter is Type:
  Filter{words: Array<U32>, mask: U32, probes: Nat}

def valid_config(+word_depth: U32, +probes: U32) -> Bool:
  (word_depth <= 15 : U32) && (probes >= 1 : U32) && (probes <= 32 : U32)

def create_checked(ok: Bool, depth: U32, probes: U32) -> Maybe<Filter>:
  match ok:
    case False{}: None{}
    case True{}:
      +d = U32.to_nat(depth)
      Some{Filter{Array.new(U32, d, 0), ((1 << Nat.add(d, 5n)) - 1 : U32), U32.to_nat(probes)}}

# m = 32 * 2^word_depth bits; bounds cap allocation at 128 KiB logical payload.
def create(+word_depth: U32, +probes: U32) -> Maybe<Filter>:
  create_checked(valid_config(word_depth, probes), word_depth, probes)

def valid_bytes_loop(xs: List<&2, U32>, valid: Bool) -> Bool:
  match xs:
    case Nil{}: valid
    case Con{h, t}: valid_bytes_loop(t, valid && (h <= 255 : U32))

def valid_bytes(xs: List<&2, U32>) -> Bool:
  valid_bytes_loop(xs, True{})

# FNV-1a over bytes, modulo 2^32. Not a cryptographic hash.
def hash(xs: List<&2, U32>, acc: U32) -> U32:
  match xs:
    case Nil{}: acc
    case Con{h, t}: hash(t, ((acc .^. h) * 16777619 : U32))

# Murmur3's 32-bit finalizer decorrelates the two seeded FNV accumulators.
def mix(+h: U32) -> U32:
  +a = ((h .^. (h >> 16n)) * 2246822507 : U32)
  +b = ((a .^. (a >> 13n)) * 3266489909 : U32)
  (b .^. (b >> 16n) : U32)

def hashes(+xs: List<&2, U32>) -> U32 & U32:
  a b = hash(xs, 2166136261) hash(xs, 3339675911)
  (mix(a), (mix(b) .|. 1 : U32))

def set_bit_finish(pair: Array<U32> & U32, index: U32, bit: U32) -> Array<U32>:
  (words, old) = pair
  words[index] <- (old .|. bit : U32)

def get_bit_finish(pair: Array<U32> & U32, bit: U32) -> Array<U32> & Bool:
  (words, value) = pair
  (words, U32.is_ne((value .&. bit : U32), 0))

def set_bit(words: Array<U32>, +pos: U32) -> Array<U32>:
  +index = (pos >> 5n : U32)
  bit = (1 << U32.to_nat((pos .&. 31 : U32)) : U32)
  set_bit_finish(words[index], index, bit)

def get_bit(words: Array<U32>, +pos: U32) -> Array<U32> & Bool:
  bit = (1 << U32.to_nat((pos .&. 31 : U32)) : U32)
  get_bit_finish(words[(pos >> 5n : U32)], bit)

def put_loop(n: Nat, words: Array<U32>, +mask: U32, +h: U32, +step: U32) -> Array<U32>:
  match n:
    case 0n: words
    case 1n+p: put_loop(p, set_bit(words, (h .&. mask : U32)), mask, (h + step : U32), step)

def query_combine(pair: Array<U32> & Bool, previous: Bool) -> Array<U32> & Bool:
  (words, found) = pair
  (words, previous && found)

def query_loop(n: Nat, pair: Array<U32> & Bool, +mask: U32, +h: U32, +step: U32) -> Array<U32> & Bool:
  match n:
    case 0n: pair
    case 1n+p:
      (words, found) = pair
      query_combine(query_loop(p, get_bit(words, (h .&. mask : U32)), mask, (h + step : U32), step), found)
def put_hashed(pair: U32 & U32, words: Array<U32>, +mask: U32, +probes: Nat) -> Filter:
  (h, step) = pair
  Filter{put_loop(probes, words, mask, h, step), mask, probes}

def query_finish(pair: Array<U32> & Bool, mask: U32, probes: Nat) -> Filter & Bool:
  (words, found) = pair
  (Filter{words, mask, probes}, found)

def query_hashed(pair: U32 & U32, words: Array<U32>, +mask: U32, +probes: Nat) -> Filter & Bool:
  (h, step) = pair
  query_finish(query_loop(probes, (words, True{}), mask, h, step), mask, probes)

def put_checked(ok: Bool, f: Filter, xs: List<&2, U32>) -> Result<&2, &1, String, Filter>:
  match ok f:
    case False{} Filter{words, mask, probes}: Fail{"byte outside 0..255"}
    case True{} Filter{words, +mask, +probes}:
      Done{put_hashed(hashes(xs), words, mask, probes)}

def put(f: Filter, +xs: List<&2, U32>) -> Result<&2, &1, String, Filter>:
  put_checked(valid_bytes(xs), f, xs)

def query_checked(ok: Bool, f: Filter, xs: List<&2, U32>) -> Result<&2, &1, String, Filter & Bool>:
  match ok f:
    case False{} Filter{words, mask, probes}: Fail{"byte outside 0..255"}
    case True{} Filter{words, +mask, +probes}:
      Done{query_hashed(hashes(xs), words, mask, probes)}

def mightContain(f: Filter, +xs: List<&2, U32>) -> Result<&2, &1, String, Filter & Bool>:
  query_checked(valid_bytes(xs), f, xs)
