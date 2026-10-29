import Base
import ./bloom.bend as Bloom

def report(result: Result<&2, &1, String, Bloom.Filter & Bool>) -> Bool:
  match result:
    case Fail{error}: False{}
    case Done{(filter, found)}: found

def query(result: Result<&2, &1, String, Bloom.Filter>) -> Bool:
  match result:
    case Fail{error}: False{}
    case Done{filter}: report(Bloom.mightContain(filter, [0, 255, 128, 0]))

def example(result: Maybe<Bloom.Filter>) -> Bool:
  match result:
    case None{}: False{}
    case Some{filter}: query(Bloom.put(filter, [0, 255, 128, 0]))

def main() -> Bool:
  example(Bloom.create(2, 3))
