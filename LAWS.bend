import Base
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
