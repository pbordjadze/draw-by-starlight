import XCTest

final class LaunchTests: XCTestCase {
    @MainActor
    func testLaunchShowsTonight() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "constellations"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Tonight"].waitForExistence(timeout: 10))
    }
}
