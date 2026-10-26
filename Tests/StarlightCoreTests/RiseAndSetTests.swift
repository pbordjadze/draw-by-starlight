import Foundation
import Testing
@testable import StarlightCore

/// Rising and setting, pinned to Jean Meeus, *Astronomical Algorithms* (2nd ed., 1998), example
/// 15.a, and to the U.S. Naval Observatory's published times (aa.usno.navy.mil, "Sun and Moon
/// Data for One Day", 2026 October 25, 40° N, 75° W).
struct RiseAndSetTests {
    let pennsylvania = Place(latitude: 40, longitude: -75)

    @Test func venusOverBoston() throws {
        // Meeus 15.a: Venus from Boston (42°20′ N, 71°05′ W) on 1988 March 20, its places at 0h TD
        // on March 19, 20 and 21 given; ΔT 56 s. It sets at 2h55m UT (0.12130 day) and rises at
        // 12h25m UT (0.51766 day).
        let boston = Place(latitude: 42.3333, longitude: -71.0833)
        let day = try moment(1988, 3, 20)
        let ra = (40.680_21, 41.731_29, 42.782_04), dec = (18.047_61, 18.440_92, 18.827_42)
        func interpolate(_ y: (Double, Double, Double), _ n: Double) -> Double {
            // Meeus 3.3.
            let a = y.1 - y.0, b = y.2 - y.1
            return y.1 + n / 2 * (a + b + n * (b - a))
        }
        let crossings = boston.crossings(from: day, to: JulianDay(day.value + 1)) { t in
            let n = t.value + 56.0 / 86_400 - day.value
            return (Equatorial(rightAscension: interpolate(ra, n), declination: interpolate(dec, n)), -0.5667)
        }
        let set = try #require(crossings.first { !$0.rising })
        let rise = try #require(crossings.first { $0.rising })
        #expect(abs(set.moment.value - day.value - 0.121_30) * 1440 < 1)
        #expect(abs(rise.moment.value - day.value - 0.517_66) * 1440 < 1)
    }

    @Test(arguments: [
        // USNO, in UT: the Moon set at 6:43 AM and rose at 5:32 PM EDT; the Sun rose at 7:21 AM
        // and set at 6:06 PM EDT.
        ("moonset", 10, 43),
        ("moonrise", 21, 32),
        ("sunrise", 11, 21),
        ("sunset", 22, 6),
    ])
    func theTwentyFifthOfOctober2026(event: String, hour: Int, minute: Int) throws {
        let midnight = try moment(2026, 10, 25, 4)
        let found: JulianDay? = switch event {
        case "moonset": pennsylvania.nextSet(of: .moon, after: midnight)
        case "moonrise": pennsylvania.nextRise(of: .moon, after: midnight)
        case "sunrise": pennsylvania.nextRise(of: .sun, after: midnight)
        default: pennsylvania.nextSet(of: .sun, after: midnight)
        }
        let published = try moment(2026, 10, 25, hour, minute)
        #expect(abs(try #require(found).value - published.value) * 1440 < 1.5)
    }

    @Test func aStarRisesAndSetsADayLess4MinutesLater() throws {
        let betelgeuse = try #require(Catalogue.bundled.stars[2061])
        let start = try moment(2026, 10, 25, 16)
        let first = try #require(pennsylvania.nextRise(of: .star(betelgeuse), after: start))
        let second = try #require(pennsylvania.nextRise(of: .star(betelgeuse), after: JulianDay(first.value + 0.5)))
        // A sidereal day is 23h56m04s.
        #expect(abs((second.value - first.value) * 86_400 - 86_164.1) < 5)
        let set = try #require(pennsylvania.nextSet(of: .star(betelgeuse), after: first))
        #expect(set > first)
    }

    @Test func polarisNeverSetsFromPennsylvania() throws {
        let polaris = try #require(Catalogue.bundled.stars[424])
        let start = try moment(2026, 10, 25)
        #expect(pennsylvania.nextRise(of: .star(polaris), after: start) == nil)
        #expect(pennsylvania.nextSet(of: .star(polaris), after: start) == nil)
    }
}
