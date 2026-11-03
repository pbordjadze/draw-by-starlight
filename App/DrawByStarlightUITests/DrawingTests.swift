import XCTest

/// Drawing Cassiopeia's W with five taps, star to star, on the demo evening; the story from
/// Wikipedia is a tap away.
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
        // The figure comes alive; its story waits for the book.
        let story = app.buttons["Story"]
        XCTAssertTrue(story.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["From Wikipedia"].exists)
        story.tap()
        XCTAssertTrue(app.staticTexts["From Wikipedia"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Schedar"].exists)
        // Its night is shown turning, and read to VoiceOver in words.
        XCTAssertTrue(app.descendants(matching: .any)["Never sets from here."].exists)
        // The story's sheet rests below the figure: every star stays in view above it. The
        // sheet's top is its Close button's, read once the sheet has stopped rising.
        let close = app.buttons["Close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        var sheetTop = close.frame.minY
        for _ in 0..<20 {
            Thread.sleep(forTimeInterval: 0.25)
            let top = close.frame.minY
            if top == sheetTop { break }
            sheetTop = top
        }
        for star in [542, 403, 264, 168, 21] {
            let frame = app.descendants(matching: .any).matching(identifier: "star-\(star)").firstMatch.frame
            XCTAssertLessThan(frame.midY, sheetTop, "star \(star) is under the story")
        }
    }
}
