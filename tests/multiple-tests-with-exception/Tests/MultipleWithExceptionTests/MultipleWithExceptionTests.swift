import XCTest

@testable import MultipleWithException

final class MultipleWithExceptionTests: XCTestCase {
  func testAdd() {
    XCTAssertEqual(sum(2, 3), 5, "2+3 should equal 5")
  }

  func testSub() {
    XCTAssertEqual(sub(2, 3), -1)
  }

  func testMul() {
    XCTAssertEqual(mul(3, 2), 6)
  }

  func testThrow() {
    XCTAssertEqual(try throwErr(2, 0), 6)
  }
}
