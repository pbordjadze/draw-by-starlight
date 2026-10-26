import Foundation
import Testing
@testable import StarlightCore

/// Julian Days pinned to published values: Jean Meeus, *Astronomical Algorithms* (2nd ed., 1998),
/// examples 7.a and 12.a, and the J2000.0 epoch.
struct JulianDayTests {
    /// A UTC date from its parts.
    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Double = 0) throws -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let whole = try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)))
        return whole.addingTimeInterval(second)
    }

    @Test func theUnixEpoch() {
        #expect(JulianDay(Date(timeIntervalSince1970: 0)).value == 2_440_587.5)
    }

    @Test func j2000IsNoonOnTheFirstOf2000() throws {
        #expect(JulianDay(try date(2000, 1, 1, 12)) == .j2000)
        #expect(JulianDay.j2000.centuriesSinceJ2000 == 0)
    }

    @Test func sputnikLaunch() throws {
        // Meeus 7.a: 1957 October 4.81 is JD 2436116.31.
        let jd = JulianDay(try date(1957, 10, 4).addingTimeInterval(0.81 * 86_400))
        #expect(abs(jd.value - 2_436_116.31) < 1e-6)
    }

    @Test func meeusSiderealTimeExample() throws {
        // Meeus 12.a: 1987 April 10 at 0h UT is JD 2446895.5, T = -0.127296372348.
        let jd = JulianDay(try date(1987, 4, 10))
        #expect(jd.value == 2_446_895.5)
        #expect(abs(jd.centuriesSinceJ2000 - -0.127_296_372_348) < 1e-12)
    }

    @Test func roundTripsThroughDate() throws {
        let moment = try date(2026, 10, 25, 21)
        #expect(abs(JulianDay(moment).date.timeIntervalSince(moment)) < 1e-3)
    }
}
