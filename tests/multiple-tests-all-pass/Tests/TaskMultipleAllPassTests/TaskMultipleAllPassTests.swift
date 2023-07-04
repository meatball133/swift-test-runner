import XCTest

@testable import MultipleAllPass

final class TaskMultipleAllPassTests: XCTestCase {
  func testAdd() {
    XCTAssertEqual(sum(2, 3), 5, "2+3 should equal 5")
  }

  func testSub() {
    XCTAssertEqual(sub(2, 3), -1)
  }

  func testMul() {
    XCTAssertEqual(mul(2, 3), 6)
  }
}

final class TaskSecondSuite: XCTestCase {
  func testAdd_2() {
    XCTAssertEqual(sum(12, 13), 25, "2+3 should equal 5")
  }

  func testSub_2() {
    XCTAssertEqual(sub(12, 13), -1)
  }

  func testMul_2() {
    XCTAssertEqual(mul(12, 13), 156)
  }
}
