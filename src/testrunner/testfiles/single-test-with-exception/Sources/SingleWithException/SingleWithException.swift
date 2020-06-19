enum TestError: Error {
    case testError(String)
}

func sum(_ x: Int, _ y: Int) throws -> Int {
    throw TestError.testError("Kaboomtown!")
}
