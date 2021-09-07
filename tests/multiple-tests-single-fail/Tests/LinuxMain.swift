import MultipleSingleFailTests
import XCTest

var tests = [XCTestCaseEntry]()
tests += MultipleSingleFailTests.allTests()
XCTMain(tests)
