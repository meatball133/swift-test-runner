import XCTest
@testable import MultipleAllPass

final class MultipleAllPassTests: XCTestCase {
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

final class SecondSuite: XCTestCase {
    func testAdd() {
        XCTAssertEqual(sum(12,13), 25, "2+3 should equal 5")
    }

    func testSub() {
        XCTAssertEqual(sub(12,13), -1)
    }

    func testMul() {
        XCTAssertEqual(mul(12,13), 156)
    }

    static var allTests = [
        ("testAdd", testAdd),
        ("testSub", testSub),
        ("testMul", testMul),
    ]
}
