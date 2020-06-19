import XCTest

import MultipleSingleFailTests

var tests = [XCTestCaseEntry]()
tests += MultipleSingleFailTests.allTests()
XCTMain(tests)
