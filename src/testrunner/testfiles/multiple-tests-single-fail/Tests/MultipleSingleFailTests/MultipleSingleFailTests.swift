import XCTest
@testable import MultipleSingleFail

final class MultipleSingleFailTests: XCTestCase {
  let runAll = Bool(ProcessInfo.processInfo.environment["RUNALL", default: "false"]) ?? false

    func testAdd() {
        XCTAssertEqual(sum(2,3), 5, "2+3 should equal 5")
    }

    func testSub() throws {
        try XCTSkipIf(true && !runAll) // change true to false to run this test
        XCTAssertEqual(sub(2,3), -1)
    }

    func testMul() throws {
        try XCTSkipIf(true && !runAll) // change true to false to run this test
        XCTAssertEqual(mul(2,3), 6)
    }

    static var allTests = [
        ("testAdd", testAdd),
        ("testSub", testSub),
        ("testMul", testMul),
    ]
}

final class SecondSuite: XCTestCase {
    let runAll = Bool(ProcessInfo.processInfo.environment["RUNALL", default: "false"]) ?? false

    func testAdd2() throws {
        try XCTSkipIf(true && !runAll) // change true to false to run this test
        XCTAssertEqual(sum(12,13), 25, "12+13 should equal 25")
    }

    func testSub2() throws {
        try XCTSkipIf(true && !runAll) // change true to false to run this test
        XCTAssertEqual(sub(12,13), -1)
    }

    func testMul2() throws {
        try XCTSkipIf(true && !runAll) // change true to false to run this test
        XCTAssertEqual(mul(12,13), 156)
    }

    static var allTests = [
        ("testAdd", testAdd2),
        ("testSub", testSub2),
        ("testMul", testMul2),
    ]
}
