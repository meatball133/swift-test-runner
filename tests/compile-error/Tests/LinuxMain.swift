import XCTest

import CompileErrorTests

var tests = [XCTestCaseEntry]()
tests += CompileErrorTests.allTests()
XCTMain(tests)
