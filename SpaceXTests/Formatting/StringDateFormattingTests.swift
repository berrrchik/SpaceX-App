import XCTest
@testable import SpaceX

final class StringDateFormattingTests: XCTestCase {
    func testFormatDateReturnsRussianFormattedDateForValidInput() {
        XCTAssertEqual("2006-03-24".formatDate(), "24 марта, 2006")
    }

    func testFormatDateUsesOnlyDatePrefixWhenTimeIsPresent() {
        XCTAssertEqual("2006-03-24T22:30:00.000Z".formatDate(), "24 марта, 2006")
    }

    func testFormatDateReturnsNilForInvalidInput() {
        XCTAssertNil("not-a-date".formatDate())
    }
}
