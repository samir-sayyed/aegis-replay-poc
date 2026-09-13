import XCTest
@testable import PocLibrary

final class StatusTests: XCTestCase {
    func testActiveStatusIsRunnable() {
        XCTAssertTrue(Status.active.isRunnable)
    }

    func testPausedStatusIsNotRunnable() {
        XCTAssertFalse(Status.paused.isRunnable)
    }
}
