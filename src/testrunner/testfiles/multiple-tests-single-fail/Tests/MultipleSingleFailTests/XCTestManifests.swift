import XCTest

#if !canImport(ObjectiveC)
  public func allTests() -> [XCTestCaseEntry] {
    return [
      testCase(MultipleSingleFailTests.allTests),
      testCase(SecondSuite.allTests),
    ]
  }
#endif
