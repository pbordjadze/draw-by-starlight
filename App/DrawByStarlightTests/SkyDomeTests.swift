import CoreGraphics
import Foundation
import StarlightCore
import Testing
@testable import DrawByStarlight

/// The home screen's sky: the moment it shows, and a touch finding the figure nearest it.
struct SkyDomeTests {
    @Test func distanceToALineIsToItsNearestPoint() {
        let a = CGPoint(x: 0, y: 0), b = CGPoint(x: 10, y: 0)
        #expect(SkyDomeView.distance(from: CGPoint(x: 5, y: 3), toSegment: a, b) == 3)
        // Past an end, the distance is to that end.
        #expect(SkyDomeView.distance(from: CGPoint(x: 13, y: 4), toSegment: a, b) == 5)
        #expect(SkyDomeView.distance(from: CGPoint(x: 3, y: 4), toSegment: a, a) == 5)
    }

    @Test func theSkyWheelsIntoTheEveningThenFollowsTheRealSky() {
        let opened = Date(timeIntervalSince1970: 1_792_976_400)
        let evening = JulianDay(opened)
        // Opening: two hours back, then the evening, as the wheel ends.
        let first = SkyDomeView.moment(evening: evening, now: opened, opened: opened, settled: false)
        #expect(abs((evening.value - first.value) * 24 - 2) < 1e-6)
        let last = SkyDomeView.moment(evening: evening, now: opened.addingTimeInterval(4), opened: opened, settled: false)
        #expect(abs(last.value - evening.value) < 1e-9)
        // Settled: the real moment, an hour on an hour later.
        let later = SkyDomeView.moment(evening: evening, now: opened.addingTimeInterval(3600), opened: opened, settled: true)
        #expect(abs((later.value - evening.value) * 24 - 1) < 1e-6)
    }

    @Test func inDaylightTheSkyHoldsAtTheComingSunset() {
        let now = Date(timeIntervalSince1970: 1_792_976_400)
        let sunset = JulianDay(now.addingTimeInterval(4 * 3600))
        #expect(SkyDomeView.moment(evening: sunset, now: now, opened: now, settled: true) == sunset)
    }

    @Test func waitingFiguresGlowOneAtATime() {
        // Held still: the first glows, the rest wait.
        #expect(SkyDomeView.glow(turn: 0, of: 3, at: nil) == 1)
        #expect(SkyDomeView.glow(turn: 1, of: 3, at: nil) == 0)
        // Halfway through the second turn: the second is at its brightest, the others dark.
        #expect(abs(SkyDomeView.glow(turn: 1, of: 3, at: 7.5) - 1) < 1e-9)
        #expect(SkyDomeView.glow(turn: 0, of: 3, at: 7.5) == 0)
        #expect(SkyDomeView.glow(turn: 2, of: 3, at: 7.5) == 0)
        // And round again.
        #expect(SkyDomeView.glow(turn: 0, of: 3, at: 16) > 0)
    }
}
