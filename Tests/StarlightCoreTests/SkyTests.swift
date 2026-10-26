import Foundation
import Testing
@testable import StarlightCore

/// A UTC moment from its parts.
func moment(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Double = 0) throws -> JulianDay {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let whole = try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)))
    return JulianDay(whole.addingTimeInterval(second))
}

/// Degrees from degrees, minutes and seconds (or hours, minutes and seconds, times 15).
func sexagesimal(_ whole: Double, _ minutes: Double, _ seconds: Double, hours: Bool = false) -> Double {
    let value = abs(whole) + minutes / 60 + seconds / 3600
    return (whole < 0 ? -value : value) * (hours ? 15 : 1)
}

/// Sidereal time, precession and the horizon, pinned to Jean Meeus, *Astronomical Algorithms*
/// (2nd ed., 1998), examples 12.a, 12.b, 21.b and 13.b.
struct SkyTests {
    @Test func siderealTimeAtMidnight() throws {
        // Meeus 12.a: 1987 April 10 at 0h UT, mean sidereal time 13h10m46.3668s.
        let gmst = try moment(1987, 4, 10).greenwichMeanSiderealTime
        #expect(abs(gmst - sexagesimal(13, 10, 46.3668, hours: true)) < 1e-6)
    }

    @Test func siderealTimeInTheEvening() throws {
        // Meeus 12.b: 1987 April 10 at 19h21m00s UT, 8h34m57.0896s = 128.7378734°.
        let gmst = try moment(1987, 4, 10, 19, 21).greenwichMeanSiderealTime
        #expect(abs(gmst - 128.737_873_4) < 1e-5)
    }

    @Test func precessionAndProperMotion() {
        // Meeus 21.b: θ Persei, J2000 2h44m11.986s +49°13′42.48″, proper motion +0.03425 s and
        // −0.0895″ a year, to 2028 November 13.19 TD: 2h46m11.331s +49°20′54.54″.
        let declination = sexagesimal(49, 13, 42.48)
        let star = Star(
            id: 0,
            j2000: Equatorial(rightAscension: sexagesimal(2, 44, 11.986, hours: true), declination: declination),
            properMotion: (0.034_25 * 15 * cos(declination * .pi / 180), -0.0895),
            magnitude: 4.1, colorIndex: nil, designation: "θ", constellation: "Per", name: nil)
        let place = star.position(at: JulianDay(2_462_088.69))
        #expect(abs(place.rightAscension - sexagesimal(2, 46, 11.331, hours: true)) < 1e-5)
        #expect(abs(place.declination - sexagesimal(49, 20, 54.54)) < 1e-5)
    }

    @Test func precessionRoundTrips() throws {
        let start = Equatorial(rightAscension: 88.792_92, declination: 7.406_94)
        let then = try moment(2026, 10, 25)
        let back = start.precessed(from: .j2000, to: then).precessed(from: then, to: .j2000)
        #expect(back.separation(from: start) < 1e-8)
    }

    @Test func venusOverWashington() {
        // Meeus 13.b: Venus at α 23h09m16.641s, δ −6°43′11.61″ from the Naval Observatory
        // (38°55′17″ N, 77°03′56″ W) at apparent sidereal time 8h34m56.853s: 15.1249° up, at
        // 68.0337° west of south.
        let venus = Equatorial(rightAscension: sexagesimal(23, 9, 16.641, hours: true), declination: sexagesimal(-6, 43, 11.61))
        let local = sexagesimal(8, 34, 56.853, hours: true) - sexagesimal(77, 3, 56)
        // Meeus rounds the hour angle he works from: a ten-thousandth of a degree.
        let seen = venus.horizontal(latitude: sexagesimal(38, 55, 17), localSiderealTime: local)
        #expect(abs(seen.altitude - 15.1249) < 2e-4)
        #expect(abs(seen.azimuth - (180 + 68.0337)) < 2e-4)
    }

    @Test func localSiderealTimeAddsTheLongitude() throws {
        let t = try moment(1987, 4, 10, 19, 21)
        let washington = Place(latitude: 38.92, longitude: -sexagesimal(77, 3, 56))
        #expect(abs(washington.siderealTime(at: t) - (128.737_873_4 - sexagesimal(77, 3, 56))) < 1e-5)
    }
}
