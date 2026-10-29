import Foundation
import Observation
import StarlightCore

/// Tonight's sky from where the stargazer is: the catalogue and the stories, the place (guessed
/// from the time zone until the place picker comes, painting-company row 128) and the moment,
/// fixed when the app opens so every screen agrees.
@Observable
final class Sky {
    let catalogue = Catalogue.bundled
    let stories = Stories.bundled
    let place: Place?
    let now: Date
    let timeZone: TimeZone

    init(place: Place?, now: Date, timeZone: TimeZone) {
        self.place = place
        self.now = now
        self.timeZone = timeZone
    }

    /// The sky as the app opens: a demo scenario's fixed evening in Debug builds, else now.
    static func tonight() -> Sky {
        #if DEBUG
        if DemoMode.isActive {
            return Sky(place: DemoMode.fixedPlace, now: DemoMode.fixedNow, timeZone: DemoMode.fixedTimeZone)
        }
        #endif
        return Sky(place: Place.guess(timeZone: .current), now: .now, timeZone: .current)
    }

    var moment: JulianDay { JulianDay(now) }

    /// The constellations that can be drawn, in the order the catalogue lists them.
    var drawable: [Constellation] {
        Catalogue.firstSet.compactMap { catalogue.constellations[$0] }
    }

    func constellation(_ id: String) -> Constellation? { catalogue.constellations[id] }

    /// A constellation laid out for drawing (`backdrop` false: only where it stands).
    func scene(_ constellation: Constellation, backdrop: Bool = true) -> FigureScene {
        FigureScene(constellation: constellation, catalogue: catalogue, place: place, now: moment, backdrop: backdrop)
    }

    /// A clock time in the stargazer's zone.
    nonisolated func time(_ moment: JulianDay) -> String {
        moment.date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, timeZone: timeZone))
    }
}
