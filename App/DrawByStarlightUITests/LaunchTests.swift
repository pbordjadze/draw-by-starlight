import XCTest

final class LaunchTests: XCTestCase {
    /// Home is tonight's sky: a figure on it, touched, opens for drawing.
    @MainActor
    func testLaunchShowsTonightsSky() {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "constellations"]
        app.launch()
        let cassiopeia = app.descendants(matching: .any).matching(identifier: "figure-Cas").firstMatch
        XCTAssertTrue(cassiopeia.waitForExistence(timeout: 10))
        XCTAssertEqual(cassiopeia.value as? String, "Drawn")
        // Orion is below the horizon on the demo evening: it waits under the sky.
        XCTAssertTrue(app.buttons["figure-Ori"].exists)
        cassiopeia.tap()
        XCTAssertTrue(app.navigationBars["Cassiopeia"].waitForExistence(timeout: 10))
    }
}
