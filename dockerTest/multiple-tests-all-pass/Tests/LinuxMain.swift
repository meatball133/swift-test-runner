import XCTest

import MultipleAllPassTests

var tests = [XCTestCaseEntry]()
tests += MultipleAllPassTests.allTests()
XCTMain(tests)
