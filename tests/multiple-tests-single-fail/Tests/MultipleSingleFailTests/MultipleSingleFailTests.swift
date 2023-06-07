import XCTest

@testable import MultipleSingleFail

final class MultipleSingleFailTests: XCTestCase {
  let runAll = Bool(ProcessInfo.processInfo.environment["RUNALL", default: "false"]) ?? false

  func testAdd() {
    XCTAssertEqual(sum(2, 3), 5, "2+3 should equal 5")
  }

  func testSub()  {
    XCTAssertEqual(sub(2, 3), -1)
  }

  func testMul() {
    XCTAssertEqual(mul(2, 3), 6)
  }

  static var allTests = [
    ("testAdd", testAdd),
    ("testSub", testSub),
    ("testMul", testMul),
  ]
}

final class SecondSuite: XCTestCase {
  let runAll = Bool(ProcessInfo.processInfo.environment["RUNALL", default: "false"]) ?? false

  func testAdd_2() {
    XCTAssertEqual(sum(12, 13), 25, "12+13 should equal 25")
  }

  func testSub_2() {
    XCTAssertEqual(sub(12, 13), -1)
  }

  func testMul_2() {
    XCTAssertEqual(mul(12, 13), 156)
  }

  static var allTests = [
    ("testAdd_2", testAdd_2),
    ("testSub_2", testSub_2),
    ("testMul_2", testMul_2),
  ]
}
