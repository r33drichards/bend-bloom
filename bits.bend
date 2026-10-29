import Base

# These are the exact word operations used by Bloom's array read/write helpers.
def add(word: U32, mask: U32) -> U32:
  (word .|. mask : U32)

def masked(word: U32, mask: U32) -> U32:
  (word .&. mask : U32)

def hit(word: U32, mask: U32) -> Bool:
  U32.is_ne(masked(word, mask), 0)

# A packed-word mask, always selecting one of its 32 positions.
def position_mask(pos: U32) -> U32:
  (1 << U32.to_nat((pos .&. 31 : U32)) : U32)
