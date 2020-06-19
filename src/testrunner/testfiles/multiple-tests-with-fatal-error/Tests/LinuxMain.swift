import XCTest

import MultipleWithFatalErrorTests

var tests = [XCTestCaseEntry]()
tests += MultipleWithFatalErrorTests.allTests()
XCTMain(tests)
