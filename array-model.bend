import Base

# Pure proof views of Base's array traversal; not used by runtime operations.
def size(a: Array<U32>) -> U32:
  match a:
    case ALeaf{word}: 1
    case ANode{left, right}: U32.shl(size(left))

def read_go(a: Array<U32>, n: U32, +index: U32, branch: Bool) -> U32:
  match a branch:
    case ALeaf{word} _: word
    case ANode{left, right} True{}:
      +half = U32.shr(n)
      read_go(left, half, index, U32.is_lt(index, U32.shr(half)))
    case ANode{left, right} False{}:
      +half = U32.shr(n)
      +next = U32.sub(index, half)
      read_go(right, half, next, U32.is_lt(next, U32.shr(half)))

def write_go(a: Array<U32>, n: U32, +index: U32, word: U32, branch: Bool) -> Array<U32>:
  match a branch:
    case ALeaf{old} _: ALeaf{word}
    case ANode{left, right} True{}:
      +half = U32.shr(n)
      ANode{write_go(left, half, index, word, U32.is_lt(index, U32.shr(half))), right}
    case ANode{left, right} False{}:
      +half = U32.shr(n)
      +next = U32.sub(index, half)
      ANode{left, write_go(right, half, next, word, U32.is_lt(next, U32.shr(half)))}
