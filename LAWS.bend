import Base
import ./array-model.bend as Model
import ./proof-observers.bend as Observe
import ./bits.bend as Bits
import ./bloom.bend as Bloom
import ./example.bend as Example

# Symbolic hash base case: the empty byte sequence leaves any seed unchanged.
law empty_hash:
  for seed: U32
  {Bloom.hash([], seed) == seed : U32}

law empty_bytes_valid:
  {Bloom.valid_bytes([]) == True{} : Bool}

law rejects_non_byte:
  {Bloom.valid_bytes([256]) == False{} : Bool}

law rejects_zero_probes:
  {Bloom.valid_config(4, 0) == False{} : Bool}

law rejects_excess_allocation:
  {Bloom.valid_config(16, 3) == False{} : Bool}

# Concrete regression theorem, not a general no-false-negative proof.
law binary_roundtrip:
  {Example.main() == True{} : Bool}

# Structural lemma for every finite bit-word width.
law word_or_idem:
  for n: Nat
  for +a: Word(n)
  {Word.or(n, a, a) == a : Word(n)}

# Structural lemma for every finite bit-word width.
law word_add_idem:
  for n: Nat
  for +a: Word(n)
  for +b: Word(n)
  {Word.or(n, Word.or(n, a, b), b) == Word.or(n, a, b) : Word(n)}

# Structural lemma for every finite bit-word width.
law word_keep_left:
  for n: Nat
  for +a: Word(n)
  for +b: Word(n)
  {Word.and(n, Word.or(n, a, b), a) == a : Word(n)}

# Structural lemma for every finite bit-word width.
law word_keep_right:
  for n: Nat
  for +a: Word(n)
  for +b: Word(n)
  {Word.and(n, Word.or(n, a, b), b) == b : Word(n)}

# Structural lemma for every finite bit-word width.
law word_or_comm:
  for n: Nat
  for +a: Word(n)
  for +b: Word(n)
  {Word.or(n, a, b) == Word.or(n, b, a) : Word(n)}

# Structural lemma for every finite bit-word width.
law word_or_assoc:
  for n: Nat
  for +a: Word(n)
  for +b: Word(n)
  for +c: Word(n)
  {Word.or(n, Word.or(n, a, b), c) == Word.or(n, a, Word.or(n, b, c)) : Word(n)}

# Structural lemma for every finite bit-word width.
law word_mask_grows:
  for n: Nat
  for +a: Word(n)
  for +b: Word(n)
  for +c: Word(n)
  {Word.and(n, Word.or(n, a, b), c) == Word.or(n, Word.and(n, a, c), Word.and(n, b, c)) : Word(n)}

law set_idempotent:
  for +a: U32
  for +b: U32
  {Bits.add(Bits.add(a, b), b) == Bits.add(a, b) : U32}

law preserves_old_bits:
  for +a: U32
  for +b: U32
  {Bits.masked(Bits.add(a, b), a) == a : U32}

law contains_new_bits:
  for +a: U32
  for +b: U32
  {Bits.masked(Bits.add(a, b), b) == b : U32}

law union_commutative:
  for +a: U32
  for +b: U32
  {Bits.add(a, b) == Bits.add(b, a) : U32}

law union_associative:
  for +a: U32
  for +b: U32
  for +c: U32
  {Bits.add(Bits.add(a, b), c) == Bits.add(a, Bits.add(b, c)) : U32}

law union_idempotent:
  for +a: U32
  {Bits.add(a, a) == a : U32}

# A nonzero inserted mask is reported present by the exact query word predicate.
law inserted_mask_hit:
  for +word: U32
  for +mask: U32
  for nonzero: {U32.is_ne(mask, 0) == True{} : Bool}
  {Bits.hit(Bits.add(word, mask), mask) == True{} : Bool}

law word_and_zero:
  for n: Nat
  for +word: Word(n)
  {Word.and(n, word, Word.zero(n)) == Word.zero(n) : Word(n)}

# Every U32 position is reduced to a valid nonzero one-bit mask.
law position_mask_nonzero:
  for +pos: U32
  {U32.is_ne(Bits.position_mask(pos), 0) == True{} : Bool}

# Actual set_bit/get_bit implementation, for a single packed word and any index.
# No premise about hash distribution or a nonzero mask is required.
law single_word_read_after_set:
  for +word: U32
  for +pos: U32
  {Bloom.get_bit(Bloom.set_bit(ALeaf{word}, pos), pos)
    == (ALeaf{Bits.add(word, Bits.position_mask(pos))}, True{}) : Array<U32> & Bool}

law single_word_set_idempotent:
  for +word: U32
  for +pos: U32
  {Bloom.set_bit(Bloom.set_bit(ALeaf{word}, pos), pos)
    == Bloom.set_bit(ALeaf{word}, pos) : Array<U32>}

# Actual insertion/query loops, one probe, arbitrary input word and hash values.
law single_word_one_probe:
  for +word: U32
  for +mask: U32
  for +hash: U32
  for +step: U32
  {Bloom.query_loop(1n, (Bloom.put_loop(1n, ALeaf{word}, mask, hash, step), True{}), mask, hash, step)
    == (ALeaf{Bits.add(word, Bits.position_mask((hash .&. mask : U32)))}, True{}) : Array<U32> & Bool}

# No false negatives for any VALID byte sequence on a single-word, one-probe
# filter, regardless of prior word contents. Uses actual checked API bodies.
law single_probe_valid_key:
  for +word: U32
  for +key: List<&2, U32>
  for valid: {Bloom.valid_bytes(key) == True{} : Bool}
  {Observe.roundtrip_checked(Bloom.valid_bytes(key), word, key) == True{} : Bool}

# All array shapes and arbitrary traversal parameters (not fixed-size examples).
law array_size_spec:
  for a: Array<U32>
  {Array.size(U32, a) == (a, Model.size(a)) : Array<U32> & U32}

law array_read_spec:
  for a: Array<U32>
  for +n: U32
  for +index: U32
  for +branch: Bool
  {Array.get.go(U32, a, n, index, branch)
    == (a, Model.read_go(a, n, index, branch)) : Array<U32> & U32}

law array_swap_spec:
  for a: Array<U32>
  for +n: U32
  for +index: U32
  for +word: U32
  for +branch: Bool
  {Array.swap.go(U32, a, n, index, word, branch)
    == (Model.write_go(a, n, index, word, branch), Model.read_go(a, n, index, branch)) : Array<U32> & U32}

law model_read_after_write:
  for a: Array<U32>
  for +n: U32
  for +index: U32
  for +word: U32
  for +branch: Bool
  {Model.read_go(Model.write_go(a, n, index, word, branch), n, index, branch) == word : U32}
