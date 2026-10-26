import Foundation

/// The Sun's apparent place, to about a hundredth of a degree (Meeus, *Astronomical Algorithms*,
/// chapter 25's lower accuracy), which places the Moon's phase and twilight well within a minute.
public struct Sun: Sendable {
    /// Its geometric ecliptic longitude for the mean equinox of the date, in degrees.
    let trueLongitude: Double
    /// Its apparent ecliptic longitude (nutation and aberration applied), in degrees.
    let apparentLongitude: Double
    /// Its distance from the Earth, in astronomical units.
    let distance: Double
    /// Its apparent right ascension and declination, for the true equator and equinox of the date.
    public let position: Equatorial

    /// The Sun at a moment (Universal Time).
    public init(at moment: JulianDay) {
        self.init(ephemeris: moment.ephemeris)
    }

    init(ephemeris jde: JulianDay) {
        let t = jde.centuriesSinceJ2000
        let meanLongitude = 280.466_46 + 36_000.769_83 * t + 0.000_303_2 * t * t
        let anomaly = 357.529_11 + 35_999.050_29 * t - 0.000_153_7 * t * t
        let eccentricity = 0.016_708_634 - 0.000_042_037 * t - 0.000_000_126_7 * t * t
        let center = (1.914_602 - 0.004_817 * t - 0.000_014 * t * t) * sin(degrees: anomaly)
            + (0.019_993 - 0.000_101 * t) * sin(degrees: 2 * anomaly)
            + 0.000_289 * sin(degrees: 3 * anomaly)
        trueLongitude = (meanLongitude + center).normalizedDegrees
        distance = 1.000_001_018 * (1 - eccentricity * eccentricity)
            / (1 + eccentricity * cos(degrees: anomaly + center))
        let node = 125.04 - 1934.136 * t
        apparentLongitude = trueLongitude - 0.005_69 - 0.004_78 * sin(degrees: node)
        let obliquity = Nutation(jde).meanObliquity + 0.002_56 * cos(degrees: node)
        position = Equatorial(eclipticLongitude: apparentLongitude, latitude: 0, obliquity: obliquity)
    }
}
