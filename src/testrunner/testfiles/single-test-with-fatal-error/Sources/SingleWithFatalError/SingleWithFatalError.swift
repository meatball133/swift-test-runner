enum TestError: Error {
  case testError(String)
}

func sum(_ x: Int, _ y: Int) -> Int {
  fatalError("Oh noes!")
}
