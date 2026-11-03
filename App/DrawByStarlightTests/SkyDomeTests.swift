import CoreGraphics
import Testing
@testable import DrawByStarlight

/// A touch on the home screen's sky finds the figure whose line is nearest it.
struct SkyDomeTests {
    @Test func distanceToALineIsToItsNearestPoint() {
        let a = CGPoint(x: 0, y: 0), b = CGPoint(x: 10, y: 0)
        #expect(SkyDomeView.distance(from: CGPoint(x: 5, y: 3), toSegment: a, b) == 3)
        // Past an end, the distance is to that end.
        #expect(SkyDomeView.distance(from: CGPoint(x: 13, y: 4), toSegment: a, b) == 5)
        #expect(SkyDomeView.distance(from: CGPoint(x: 3, y: 4), toSegment: a, a) == 5)
    }
}
