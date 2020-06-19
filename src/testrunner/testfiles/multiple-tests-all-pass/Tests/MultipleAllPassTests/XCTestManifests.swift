import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MultipleAllPassTests.allTests),
        testCase(SecondSuite.allTests),
    ]
}
#endif
