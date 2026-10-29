#if DEBUG
import Foundation
import StarlightCore
import os

/// Deterministic, launch-argument-driven app states for screenshots and UI tests.
///
///     xcrun simctl launch <udid> com.pbordjadze.drawbystarlight -demo tonight-empty
///
/// Scenario names are owned by the views that render them (`TonightView`, `DrawingView`). Every
/// scenario shows one evening, `fixedNow` from `fixedPlace`, the sky `FigureSceneTests` pins. Scenarios named
/// `*-long-text` are captured with every localized string doubled (`ci/screenshots.sh`); the rest
/// of the name picks the state. The app is always dark, so there are no `-dark` variants.
///
/// Debug builds only: the demo types are compiled out of Release builds, so a shipped app has no
/// launch argument that swaps its content (`ci/check_release.sh` checks).
enum DemoMode {
    /// The requested scenario, e.g. "tonight-empty".
    static let scenario: String? = UserDefaults.standard.string(forKey: "demo")

    static var isActive: Bool { scenario != nil }

    /// 2026 October 25 at 9:00 PM EDT (01:00 UT on the 26th), from 40° N, 75° W.
    static let fixedNow = Date(timeIntervalSince1970: 1_792_976_400)
    static let fixedPlace = Place(latitude: 40, longitude: -75)
    static let fixedTimeZone = TimeZone(identifier: "America/New_York")!

    /// `tmp/demo-ready` in the app's data container. CI screenshots a scenario shortly after
    /// this file appears instead of sleeping for a worst-case delay.
    static let readyMarker = FileManager.default.temporaryDirectory.appending(path: "demo-ready")

    /// Signals that the scenario's content is on screen; only animations are still settling.
    static func markReady() {
        guard isActive else { return }
        FileManager.default.createFile(atPath: readyMarker.path, contents: Data())
        Log.demo.info("demo-ready \(scenario ?? "", privacy: .public)")
    }
}
#endif
