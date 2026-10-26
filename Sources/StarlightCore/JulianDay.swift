import Foundation

/// A moment as a Julian Day: days, with their fraction, since noon (UT) of January 1, 4713 BC in
/// the proleptic Julian calendar. Every sky computation (sidereal time, precession, the Moon)
/// starts from it. Universal Time is taken as the clock's UTC: the leap seconds between them are
/// below a second, far finer than anything the app draws.
public struct JulianDay: Sendable, Hashable, Comparable {
    public let value: Double

    public init(_ value: Double) {
        self.value = value
    }

    /// The Julian Day of the Unix epoch, 1970-01-01 00:00 UT.
    static let unixEpoch = 2_440_587.5
    /// J2000.0, 2000-01-01 12:00, the epoch of the star catalogue's positions.
    public static let j2000 = JulianDay(2_451_545.0)

    public init(_ date: Date) {
        value = date.timeIntervalSince1970 / 86_400 + Self.unixEpoch
    }

    public var date: Date {
        Date(timeIntervalSince1970: (value - Self.unixEpoch) * 86_400)
    }

    /// Julian centuries of 36,525 days since J2000.0: the time argument of the IAU's formulas.
    public var centuriesSinceJ2000: Double {
        (value - Self.j2000.value) / 36_525
    }

    public static func < (a: JulianDay, b: JulianDay) -> Bool { a.value < b.value }
}
