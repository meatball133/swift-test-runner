import XCTest

@testable import SingleThatPasses

final class SingleThatPassesTests: XCTestCase {
  func testAdd() {
    XCTAssertEqual(sum(2, 3), 5, "2+3 should equal 5")
  }
}
