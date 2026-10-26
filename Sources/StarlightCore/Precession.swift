import Foundation

extension Equatorial {
    /// This direction, given for the mean equator and equinox of `start`, for those of `end`
    /// (Meeus, *Astronomical Algorithms*, 21.2 to 21.4: the IAU's rigorous precession).
    public func precessed(from start: JulianDay, to end: JulianDay) -> Equatorial {
        let bigT = start.centuriesSinceJ2000
        let t = (end.value - start.value) / 36_525
        let rate = 2306.2181 + 1.396_56 * bigT - 0.000_139 * bigT * bigT
        let zeta = (rate * t + (0.301_88 - 0.000_344 * bigT) * t * t + 0.017_998 * t * t * t) / 3600
        let z = (rate * t + (1.094_68 + 0.000_066 * bigT) * t * t + 0.018_203 * t * t * t) / 3600
        let theta = ((2004.3109 - 0.853_30 * bigT - 0.000_217 * bigT * bigT) * t
            - (0.426_65 + 0.000_217 * bigT) * t * t - 0.041_833 * t * t * t) / 3600
        let a = cos(degrees: declination) * sin(degrees: rightAscension + zeta)
        let b = cos(degrees: theta) * cos(degrees: declination) * cos(degrees: rightAscension + zeta)
            - sin(degrees: theta) * sin(degrees: declination)
        let c = sin(degrees: theta) * cos(degrees: declination) * cos(degrees: rightAscension + zeta)
            + cos(degrees: theta) * sin(degrees: declination)
        return Equatorial(rightAscension: atan2Degrees(a, b) + z, declination: asinDegrees(c))
    }

    /// The direction of ecliptic longitude and latitude `longitude`, `latitude` for an obliquity
    /// of the ecliptic `obliquity` (Meeus 13.3 and 13.4), all in degrees.
    init(eclipticLongitude longitude: Double, latitude: Double, obliquity: Double) {
        self.init(
            rightAscension: atan2Degrees(
                sin(degrees: longitude) * cos(degrees: obliquity) - tan(degrees: latitude) * sin(degrees: obliquity),
                cos(degrees: longitude)),
            declination: asinDegrees(sin(degrees: latitude) * cos(degrees: obliquity)
                + cos(degrees: latitude) * sin(degrees: obliquity) * sin(degrees: longitude)))
    }
}

/// Nutation in longitude and in obliquity, to about half an arcsecond, and the obliquity of the
/// ecliptic (Meeus 22.2 and chapter 22's shorter series), for a moment in dynamical time.
struct Nutation {
    /// Δψ, in degrees.
    let longitude: Double
    /// Δε, in degrees.
    let obliquity: Double
    /// ε0, the mean obliquity of the ecliptic, in degrees.
    let meanObliquity: Double

    init(_ jde: JulianDay) {
        let t = jde.centuriesSinceJ2000
        let node = 125.044_52 - 1934.136_261 * t
        let sun = 280.4665 + 36_000.7698 * t
        let moon = 218.3165 + 481_267.8813 * t
        longitude = (-17.20 * sin(degrees: node) - 1.32 * sin(degrees: 2 * sun)
            - 0.23 * sin(degrees: 2 * moon) + 0.21 * sin(degrees: 2 * node)) / 3600
        obliquity = (9.20 * cos(degrees: node) + 0.57 * cos(degrees: 2 * sun)
            + 0.10 * cos(degrees: 2 * moon) - 0.09 * cos(degrees: 2 * node)) / 3600
        meanObliquity = 23 + 26 / 60.0 + (21.448 - 46.8150 * t - 0.000_59 * t * t + 0.001_813 * t * t * t) / 3600
    }

    /// ε, the true obliquity of the ecliptic, in degrees.
    var trueObliquity: Double { meanObliquity + obliquity }
}
