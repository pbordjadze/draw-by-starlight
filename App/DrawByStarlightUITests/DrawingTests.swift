import XCTest

/// Drawing Cassiopeia's W with five taps, star to star, on the demo evening; the story from
/// Wikipedia follows.
final class DrawingTests: XCTestCase {
    @MainActor
    func testDrawingCassiopeiaBringsItsStory() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "draw-cassiopeia"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Cassiopeia"].waitForExistence(timeout: 10))
        for star in [542, 403, 264, 168, 21] {
            let element = app.descendants(matching: .any).matching(identifier: "star-\(star)").firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: 5), "star \(star)")
            element.tap()
        }
        XCTAssertTrue(app.staticTexts["From Wikipedia"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Schedar"].exists)
    }
}
