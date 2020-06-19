import XCTest

import SingleThatFailsTests

var tests = [XCTestCaseEntry]()
tests += SingleThatFailsTests.allTests()
XCTMain(tests)
