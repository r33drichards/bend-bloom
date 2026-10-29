import Base
import ./bloom.bend as Bloom

# Proof-only observers discard the affine filter after inspecting its answer.
def answer(result: Result<&2, &1, String, Bloom.Filter & Bool>) -> Bool:
  match result:
    case Fail{error}: False{}
    case Done{(filter, found)}: found

def after_put(result: Result<&2, &1, String, Bloom.Filter>, ok: Bool, key: List<&2, U32>) -> Bool:
  match result:
    case Fail{error}: False{}
    case Done{filter}: answer(Bloom.query_checked(ok, filter, key))

# Same validation value used by public put and mightContain for the same key.
def roundtrip_checked(+ok: Bool, word: U32, +key: List<&2, U32>) -> Bool:
  after_put(Bloom.put_checked(ok, Bloom.Filter{ALeaf{word}, 31, 1n}, key), ok, key)
