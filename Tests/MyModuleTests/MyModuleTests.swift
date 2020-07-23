import XCTest
@testable import MyModule

final class MyModuleTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MyModule().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
