import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(TaskMultipleAllPassTests.allTests),
        testCase(TaskSecondSuite.allTests),
    ]
}
#endif
