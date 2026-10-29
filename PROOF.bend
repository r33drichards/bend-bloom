import Base
import ./array-model.bend as Model
import ./bloom.bend as Bloom
import ./proof-observers.bend as Observe
import ./bits.bend as Bits
import ./LAWS.bend as Laws

def Laws.empty_hash(seed): {==}
def Laws.empty_bytes_valid(): {==}
def Laws.rejects_non_byte(): {==}
def Laws.rejects_zero_probes(): {==}
def Laws.rejects_excess_allocation(): {==}
def Laws.binary_roundtrip(): {==}

def Laws.word_or_idem(n, a):
  match n:
    case 0n:
      match a:
        case WNil{}: {==}
    case 1n+p:
      match a:
        case WCon{False{}, at}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.or(p, at, at), at, Laws.word_or_idem(p, at))
        case WCon{True{}, at}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.or(p, at, at), at, Laws.word_or_idem(p, at))

def Laws.word_add_idem(n, a, b):
  match n:
    case 0n:
      match a b:
        case WNil{} WNil{}: {==}
    case 1n+p:
      match a b:
        case WCon{False{}, at} WCon{False{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.or(p, Word.or(p, at, bt), bt), Word.or(p, at, bt), Laws.word_add_idem(p, at, bt))
        case WCon{False{}, at} WCon{True{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.or(p, Word.or(p, at, bt), bt), Word.or(p, at, bt), Laws.word_add_idem(p, at, bt))
        case WCon{True{}, at} WCon{False{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.or(p, Word.or(p, at, bt), bt), Word.or(p, at, bt), Laws.word_add_idem(p, at, bt))
        case WCon{True{}, at} WCon{True{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.or(p, Word.or(p, at, bt), bt), Word.or(p, at, bt), Laws.word_add_idem(p, at, bt))

def Laws.word_keep_left(n, a, b):
  match n:
    case 0n:
      match a b:
        case WNil{} WNil{}: {==}
    case 1n+p:
      match a b:
        case WCon{False{}, at} WCon{False{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.and(p, Word.or(p, at, bt), at), at, Laws.word_keep_left(p, at, bt))
        case WCon{False{}, at} WCon{True{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.and(p, Word.or(p, at, bt), at), at, Laws.word_keep_left(p, at, bt))
        case WCon{True{}, at} WCon{False{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.and(p, Word.or(p, at, bt), at), at, Laws.word_keep_left(p, at, bt))
        case WCon{True{}, at} WCon{True{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.and(p, Word.or(p, at, bt), at), at, Laws.word_keep_left(p, at, bt))

def Laws.word_keep_right(n, a, b):
  match n:
    case 0n:
      match a b:
        case WNil{} WNil{}: {==}
    case 1n+p:
      match a b:
        case WCon{False{}, at} WCon{False{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.and(p, Word.or(p, at, bt), bt), bt, Laws.word_keep_right(p, at, bt))
        case WCon{False{}, at} WCon{True{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.and(p, Word.or(p, at, bt), bt), bt, Laws.word_keep_right(p, at, bt))
        case WCon{True{}, at} WCon{False{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.and(p, Word.or(p, at, bt), bt), bt, Laws.word_keep_right(p, at, bt))
        case WCon{True{}, at} WCon{True{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.and(p, Word.or(p, at, bt), bt), bt, Laws.word_keep_right(p, at, bt))

def Laws.word_or_comm(n, a, b):
  match n:
    case 0n:
      match a b:
        case WNil{} WNil{}: {==}
    case 1n+p:
      match a b:
        case WCon{False{}, at} WCon{False{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.or(p, at, bt), Word.or(p, bt, at), Laws.word_or_comm(p, at, bt))
        case WCon{False{}, at} WCon{True{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.or(p, at, bt), Word.or(p, bt, at), Laws.word_or_comm(p, at, bt))
        case WCon{True{}, at} WCon{False{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.or(p, at, bt), Word.or(p, bt, at), Laws.word_or_comm(p, at, bt))
        case WCon{True{}, at} WCon{True{}, bt}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.or(p, at, bt), Word.or(p, bt, at), Laws.word_or_comm(p, at, bt))

def Laws.word_or_assoc(n, a, b, c):
  match n:
    case 0n:
      match a b c:
        case WNil{} WNil{} WNil{}: {==}
    case 1n+p:
      match a b c:
        case WCon{False{}, at} WCon{False{}, bt} WCon{False{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.or(p, Word.or(p, at, bt), ct), Word.or(p, at, Word.or(p, bt, ct)), Laws.word_or_assoc(p, at, bt, ct))
        case WCon{False{}, at} WCon{False{}, bt} WCon{True{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.or(p, Word.or(p, at, bt), ct), Word.or(p, at, Word.or(p, bt, ct)), Laws.word_or_assoc(p, at, bt, ct))
        case WCon{False{}, at} WCon{True{}, bt} WCon{False{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.or(p, Word.or(p, at, bt), ct), Word.or(p, at, Word.or(p, bt, ct)), Laws.word_or_assoc(p, at, bt, ct))
        case WCon{False{}, at} WCon{True{}, bt} WCon{True{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.or(p, Word.or(p, at, bt), ct), Word.or(p, at, Word.or(p, bt, ct)), Laws.word_or_assoc(p, at, bt, ct))
        case WCon{True{}, at} WCon{False{}, bt} WCon{False{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.or(p, Word.or(p, at, bt), ct), Word.or(p, at, Word.or(p, bt, ct)), Laws.word_or_assoc(p, at, bt, ct))
        case WCon{True{}, at} WCon{False{}, bt} WCon{True{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.or(p, Word.or(p, at, bt), ct), Word.or(p, at, Word.or(p, bt, ct)), Laws.word_or_assoc(p, at, bt, ct))
        case WCon{True{}, at} WCon{True{}, bt} WCon{False{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.or(p, Word.or(p, at, bt), ct), Word.or(p, at, Word.or(p, bt, ct)), Laws.word_or_assoc(p, at, bt, ct))
        case WCon{True{}, at} WCon{True{}, bt} WCon{True{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.or(p, Word.or(p, at, bt), ct), Word.or(p, at, Word.or(p, bt, ct)), Laws.word_or_assoc(p, at, bt, ct))

def Laws.word_mask_grows(n, a, b, c):
  match n:
    case 0n:
      match a b c:
        case WNil{} WNil{} WNil{}: {==}
    case 1n+p:
      match a b c:
        case WCon{False{}, at} WCon{False{}, bt} WCon{False{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.and(p, Word.or(p, at, bt), ct), Word.or(p, Word.and(p, at, ct), Word.and(p, bt, ct)), Laws.word_mask_grows(p, at, bt, ct))
        case WCon{False{}, at} WCon{False{}, bt} WCon{True{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.and(p, Word.or(p, at, bt), ct), Word.or(p, Word.and(p, at, ct), Word.and(p, bt, ct)), Laws.word_mask_grows(p, at, bt, ct))
        case WCon{False{}, at} WCon{True{}, bt} WCon{False{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.and(p, Word.or(p, at, bt), ct), Word.or(p, Word.and(p, at, ct), Word.and(p, bt, ct)), Laws.word_mask_grows(p, at, bt, ct))
        case WCon{False{}, at} WCon{True{}, bt} WCon{True{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.and(p, Word.or(p, at, bt), ct), Word.or(p, Word.and(p, at, ct), Word.and(p, bt, ct)), Laws.word_mask_grows(p, at, bt, ct))
        case WCon{True{}, at} WCon{False{}, bt} WCon{False{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.and(p, Word.or(p, at, bt), ct), Word.or(p, Word.and(p, at, ct), Word.and(p, bt, ct)), Laws.word_mask_grows(p, at, bt, ct))
        case WCon{True{}, at} WCon{False{}, bt} WCon{True{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.and(p, Word.or(p, at, bt), ct), Word.or(p, Word.and(p, at, ct), Word.and(p, bt, ct)), Laws.word_mask_grows(p, at, bt, ct))
        case WCon{True{}, at} WCon{True{}, bt} WCon{False{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.and(p, Word.or(p, at, bt), ct), Word.or(p, Word.and(p, at, ct), Word.and(p, bt, ct)), Laws.word_mask_grows(p, at, bt, ct))
        case WCon{True{}, at} WCon{True{}, bt} WCon{True{}, ct}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{True{}, w},
            Word.and(p, Word.or(p, at, bt), ct), Word.or(p, Word.and(p, at, ct), Word.and(p, bt, ct)), Laws.word_mask_grows(p, at, bt, ct))

def Laws.set_idempotent(a, b):
  match a b:
    case U32{aw} U32{bw}:
      Equal.cong(Word(32n), U32, w => U32{w},
        Word.or(32n, Word.or(32n, aw, bw), bw), Word.or(32n, aw, bw), Laws.word_add_idem(32n, aw, bw))

def Laws.preserves_old_bits(a, b):
  match a b:
    case U32{aw} U32{bw}:
      Equal.cong(Word(32n), U32, w => U32{w},
        Word.and(32n, Word.or(32n, aw, bw), aw), aw, Laws.word_keep_left(32n, aw, bw))

def Laws.contains_new_bits(a, b):
  match a b:
    case U32{aw} U32{bw}:
      Equal.cong(Word(32n), U32, w => U32{w},
        Word.and(32n, Word.or(32n, aw, bw), bw), bw, Laws.word_keep_right(32n, aw, bw))

def Laws.union_commutative(a, b):
  match a b:
    case U32{aw} U32{bw}:
      Equal.cong(Word(32n), U32, w => U32{w},
        Word.or(32n, aw, bw), Word.or(32n, bw, aw), Laws.word_or_comm(32n, aw, bw))

def Laws.union_associative(a, b, c):
  match a b c:
    case U32{aw} U32{bw} U32{cw}:
      Equal.cong(Word(32n), U32, w => U32{w},
        Word.or(32n, Word.or(32n, aw, bw), cw), Word.or(32n, aw, Word.or(32n, bw, cw)), Laws.word_or_assoc(32n, aw, bw, cw))

def Laws.union_idempotent(a):
  match a:
    case U32{aw}:
      Equal.cong(Word(32n), U32, w => U32{w},
        Word.or(32n, aw, aw), aw, Laws.word_or_idem(32n, aw))

def Laws.inserted_mask_hit(word, mask, nonzero):
  Equal.trans(Bool, Bits.hit(Bits.add(word, mask), mask), U32.is_ne(mask, 0), True{},
    Equal.cong(U32, Bool, w => U32.is_ne(w, 0),
      Bits.masked(Bits.add(word, mask), mask), mask, Laws.contains_new_bits(word, mask)), nonzero)

def Laws.word_and_zero(n, word):
  match n:
    case 0n:
      match word:
        case WNil{}: {==}
    case 1n+p:
      match word:
        case WCon{False{}, tail}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.and(p, tail, Word.zero(p)), Word.zero(p), Laws.word_and_zero(p, tail))
        case WCon{True{}, tail}:
          Equal.cong(Word(p), Word(1n+p), w => WCon{False{}, w},
            Word.and(p, tail, Word.zero(p)), Word.zero(p), Laws.word_and_zero(p, tail))

def Laws.position_mask_nonzero(pos):
  match pos:
    case U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{False{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))
    case U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, tail}}}}}}:
      Equal.cong(U32, Bool, x => U32.is_ne((1 << U32.to_nat(x) : U32), 0),
        U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, Word.and(27n, tail, Word.zero(27n))}}}}}}, U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, Word.zero(27n)}}}}}},
        Equal.cong(Word(27n), U32, w => U32{WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, WCon{True{}, w}}}}}},
          Word.and(27n, tail, Word.zero(27n)), Word.zero(27n), Laws.word_and_zero(27n, tail)))

def Laws.single_word_read_after_set(word, pos):
  Equal.cong(Bool, Array<U32> & Bool,
    b => (ALeaf{Bits.add(word, Bits.position_mask(pos))}, b),
    Bits.hit(Bits.add(word, Bits.position_mask(pos)), Bits.position_mask(pos)), True{},
    Laws.inserted_mask_hit(word, Bits.position_mask(pos), Laws.position_mask_nonzero(pos)))

def Laws.single_word_set_idempotent(word, pos):
  Equal.cong(U32, Array<U32>, w => ALeaf{w},
    Bits.add(Bits.add(word, Bits.position_mask(pos)), Bits.position_mask(pos)),
    Bits.add(word, Bits.position_mask(pos)), Laws.set_idempotent(word, Bits.position_mask(pos)))

def Laws.single_word_one_probe(word, mask, hash, step):
  Laws.single_word_read_after_set(word, (hash .&. mask : U32))

def Laws.single_probe_valid_key(word, key, valid):
  Equal.trans(Bool, Observe.roundtrip_checked(Bloom.valid_bytes(key), word, key),
    Observe.roundtrip_checked(True{}, word, key), True{},
    Equal.cong(Bool, Bool, ok => Observe.roundtrip_checked(ok, word, key),
      Bloom.valid_bytes(key), True{}, valid),
    Laws.inserted_mask_hit(word, Bits.position_mask((Bloom.mix(Bloom.hash(key, 2166136261)) .&. 31 : U32)),
      Laws.position_mask_nonzero((Bloom.mix(Bloom.hash(key, 2166136261)) .&. 31 : U32))))

def Laws.array_size_spec(a):
  match a:
    case ALeaf{word}: {==}
    case ANode{left, right}:
      Equal.cong(Array<U32> & U32, Array<U32> & U32, pair => Array.size.node(U32, right, pair),
        Array.size(U32, left), (left, Model.size(left)), Laws.array_size_spec(left))

def Laws.array_read_spec(a, n, index, branch):
  match a branch:
    case ALeaf{word} _: {==}
    case ANode{left, right} True{}:
      +half = U32.shr(n)
      +next_branch = U32.is_lt(index, U32.shr(half))
      Equal.cong(Array<U32> & U32, Array<U32> & U32, pair => Array.swap.lo(U32, right, pair),
        Array.get.go(U32, left, half, index, next_branch),
        (left, Model.read_go(left, half, index, next_branch)),
        Laws.array_read_spec(left, half, index, next_branch))
    case ANode{left, right} False{}:
      +half = U32.shr(n)
      +next = U32.sub(index, half)
      +next_branch = U32.is_lt(next, U32.shr(half))
      Equal.cong(Array<U32> & U32, Array<U32> & U32, pair => Array.swap.hi(U32, left, pair),
        Array.get.go(U32, right, half, next, next_branch),
        (right, Model.read_go(right, half, next, next_branch)),
        Laws.array_read_spec(right, half, next, next_branch))

def Laws.array_swap_spec(a, n, index, word, branch):
  match a branch:
    case ALeaf{old} _: {==}
    case ANode{left, right} True{}:
      +half = U32.shr(n)
      +next_branch = U32.is_lt(index, U32.shr(half))
      Equal.cong(Array<U32> & U32, Array<U32> & U32, pair => Array.swap.lo(U32, right, pair),
        Array.swap.go(U32, left, half, index, word, next_branch),
        (Model.write_go(left, half, index, word, next_branch), Model.read_go(left, half, index, next_branch)),
        Laws.array_swap_spec(left, half, index, word, next_branch))
    case ANode{left, right} False{}:
      +half = U32.shr(n)
      +next = U32.sub(index, half)
      +next_branch = U32.is_lt(next, U32.shr(half))
      Equal.cong(Array<U32> & U32, Array<U32> & U32, pair => Array.swap.hi(U32, left, pair),
        Array.swap.go(U32, right, half, next, word, next_branch),
        (Model.write_go(right, half, next, word, next_branch), Model.read_go(right, half, next, next_branch)),
        Laws.array_swap_spec(right, half, next, word, next_branch))

def Laws.model_read_after_write(a, n, index, word, branch):
  match a branch:
    case ALeaf{old} _: {==}
    case ANode{left, right} True{}:
      +half = U32.shr(n)
      Laws.model_read_after_write(left, half, index, word, U32.is_lt(index, U32.shr(half)))
    case ANode{left, right} False{}:
      +half = U32.shr(n)
      +next = U32.sub(index, half)
      Laws.model_read_after_write(right, half, next, word, U32.is_lt(next, U32.shr(half)))
