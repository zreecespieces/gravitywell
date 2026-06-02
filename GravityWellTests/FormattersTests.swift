import XCTest
@testable import GravityWell

final class FormattersTests: XCTestCase {
    func testPercentFormattingUsesOneFractionDigit() {
        XCTAssertEqual(Formatters.percent(18.74), "18.7%")
    }

    func testIntegerFormattingUsesGrouping() {
        XCTAssertEqual(Formatters.integer(12_483), "12,483")
    }
}
