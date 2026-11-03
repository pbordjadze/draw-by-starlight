import Foundation
import StarlightCore
import Testing
@testable import DrawByStarlight

/// The story sheet's night: the wake behind the figure trails it, a dozen steps long at most.
struct FigureNightTests {
    let evening = JulianDay(2_461_339.5)
    var dawn: JulianDay { JulianDay(evening.value + 0.5) }

    func at(_ step: Double) -> JulianDay { JulianDay(evening.value + 0.5 * step / 96) }

    @Test func noWakeOutsideTheNightOrAtItsStart() {
        #expect(FigureNightView.wake(at: JulianDay(evening.value - 0.1), evening: evening, dawn: dawn, steps: 96) == nil)
        #expect(FigureNightView.wake(at: evening, evening: evening, dawn: dawn, steps: 96) == nil)
        #expect(FigureNightView.wake(at: JulianDay(dawn.value + 0.1), evening: evening, dawn: dawn, steps: 96) == nil)
    }

    @Test func theWakeTrailsTheFigure() {
        #expect(FigureNightView.wake(at: at(5), evening: evening, dawn: dawn, steps: 96) == 0..<5)
        #expect(FigureNightView.wake(at: at(50), evening: evening, dawn: dawn, steps: 96) == 38..<50)
        // Between steps, it never runs ahead.
        #expect(FigureNightView.wake(at: at(50.9), evening: evening, dawn: dawn, steps: 96) == 38..<50)
    }
}
