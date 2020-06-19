import XCTest
@testable import CompileError

final class CompileErrorTests: XCTestCase {
    func testAdd() {
        XCTAssertEqual(sum(2,3), 5)
    }

    static var allTests = [
        ("testAdd", testAdd),
    ]
}
