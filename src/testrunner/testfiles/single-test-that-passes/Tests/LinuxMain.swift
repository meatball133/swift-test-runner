import XCTest

import SingleThatPassesTests

var tests = [XCTestCaseEntry]()
tests += SingleThatPassesTests.allTests()
XCTMain(tests)
