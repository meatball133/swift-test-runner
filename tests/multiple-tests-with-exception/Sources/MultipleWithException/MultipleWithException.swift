enum TestError: Error {
  case testError(String)
}

func sum(_ x: Int, _ y: Int) -> Int {
  return x + y
}

func sub(_ x: Int, _ y: Int) -> Int {
  //    fatalError("Oh noes!")
  return x - y
}

func mul(_ x: Int, _ y: Int) -> Int {
  if x < y {
    fatalError("Oh noes!")
  } else {
    return x * y
    //        let z = Int.max / y
    //        return x * z
  }
}

func throwErr(_ x: Int, _ y: Int) throws -> Int {
  guard y != 0 else { throw TestError.testError("Oh noes! Div by zeroes!!!") }
  return x / y
}
