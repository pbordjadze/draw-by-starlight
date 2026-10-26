import Foundation
import Testing
@testable import StarlightCore

/// The Sun and the Moon, pinned to Jean Meeus, *Astronomical Algorithms* (2nd ed., 1998), examples
/// 25.a, 47.a, 48.a and 49.a; to the U.S. Naval Observatory's published phases of the Moon
/// (aa.usno.navy.mil, "Phases of the Moon", October 2026); and to JPL's Horizons ephemeris.
struct SunAndMoonTests {
    @Test func theSunInOctober1992() {
        // Meeus 25.a: 1992 October 13.0 TD: true longitude 199.90988°, distance 0.99766 AU,
        // apparent α 198.38083°, δ −7.78507°.
        let sun = Sun(ephemeris: JulianDay(2_448_908.5))
        #expect(abs(sun.trueLongitude - 199.909_88) < 2e-5)
        #expect(abs(sun.distance - 0.997_66) < 1e-5)
        #expect(abs(sun.position.rightAscension - 198.380_83) < 1e-4)
        #expect(abs(sun.position.declination - -7.785_07) < 1e-4)
    }

    @Test func theMoonInApril1992() {
        // Meeus 47.a: 1992 April 12.0 TD: λ 133.162655°, β −3.229126°, Δ 368409.7 km,
        // π 0.991990°, apparent α 134.688470°, δ 13.768368°.
        let moon = Moon(ephemeris: JulianDay(2_448_724.5))
        #expect(abs(moon.longitude - 133.162_655) < 2e-6)
        #expect(abs(moon.latitude - -3.229_126) < 2e-6)
        #expect(abs(moon.distance - 368_409.7) < 0.1)
        #expect(abs(moon.parallax - 0.991_990) < 1e-6)
        // The shorter nutation series is good to half an arcsecond.
        #expect(abs(moon.position.rightAscension - 134.688_470) < 3e-4)
        #expect(abs(moon.position.declination - 13.768_368) < 3e-4)
    }

    @Test func itsPhaseInApril1992() {
        // Meeus 48.a: the same moment: phase angle 69.0756°, illuminated fraction 0.6786, waxing.
        let moon = Moon(ephemeris: JulianDay(2_448_724.5))
        #expect(abs(moon.phaseAngle - 69.0756) < 0.01)
        #expect(abs(moon.illuminatedFraction - 0.6786) < 2e-4)
        #expect(moon.isWaxing)
    }

    @Test func theNewMoonOfFebruary1977() throws {
        // Meeus 49.a: 1977 February 18, 3h37m42s TD (JDE 2443192.65118); ΔT was 48 seconds.
        let new = Moon.next(.new, after: try moment(1977, 2, 10))
        #expect(abs(new.value - (2_443_192.651_18 - 48.0 / 86_400)) * 1440 < 2)
    }

    @Test(arguments: [
        // USNO, October 2026, in UT.
        (Moon.Phase.lastQuarter, 3, 13, 25),
        (.new, 10, 15, 50),
        (.firstQuarter, 18, 16, 12),
        (.full, 26, 4, 12),
    ])
    func thePhasesOfOctober2026(phase: Moon.Phase, day: Int, hour: Int, minute: Int) throws {
        let found = Moon.next(phase, after: try moment(2026, 10, 1))
        #expect(abs(found.value - (try moment(2026, 10, day, hour, minute)).value) * 1440 < 1.5)
    }

    @Test func theHuntersMoonIsFullAndWaning() throws {
        let night = try moment(2026, 10, 26, 6)
        let moon = Moon(at: night)
        #expect(moon.illuminatedFraction > 0.99)
        #expect(!moon.isWaxing)
    }

    @Test func theMoonOverPennsylvania() throws {
        // JPL Horizons (ssd.jpl.nasa.gov), the Moon from 40° N, 75° W at sea level, 2026 October 26
        // 01:00 UT, apparent and airless: azimuth 102.092864°, elevation 37.803212°.
        let seen = Place(latitude: 40, longitude: -75).horizontal(of: .moon, at: try moment(2026, 10, 26, 1))
        #expect(abs(seen.azimuth - 102.092_864) < 0.01)
        #expect(abs(seen.altitude - 37.803_212) < 0.01)
    }
}
