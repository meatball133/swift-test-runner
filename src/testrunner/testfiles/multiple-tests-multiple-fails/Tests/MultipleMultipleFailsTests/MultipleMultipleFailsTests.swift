import XCTest
@testable import MultipleMultipleFails

final class MultipleMultipleFailsTests: XCTestCase {
    func testAdd() {
        XCTAssertEqual(sum(2,3), 5, "2+3 should equal 5")
    }

    func testSub() {
        XCTAssertEqual(sub(2,3), -1)
    }

    func testMul() {
        XCTAssertEqual(mul(2,3), 6)
    }

    static var allTests = [
        ("testAdd", testAdd),
        ("testSub", testSub),
        ("testMul", testMul),
    ]
}
