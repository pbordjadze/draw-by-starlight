import Foundation

extension JulianDay {
    /// Greenwich mean sidereal time, in degrees (Meeus, *Astronomical Algorithms*, 12.4).
    public var greenwichMeanSiderealTime: Double {
        let t = centuriesSinceJ2000
        return (280.460_618_37 + 360.985_647_366_29 * (value - Self.j2000.value)
            + 0.000_387_933 * t * t - t * t * t / 38_710_000).normalizedDegrees
    }

    /// The same moment in Terrestrial (dynamical) Time, the time the Sun's and Moon's theories run
    /// on: this Universal Time plus ΔT.
    var ephemeris: JulianDay {
        JulianDay(value + Self.deltaT(year: 2000 + (value - Self.j2000.value) / 365.25) / 86_400)
    }

    /// ΔT = TT − UT in seconds: Espenak and Meeus's polynomials for 1961 to 2150 (NASA, "Polynomial
    /// Expressions for Delta T", Five Millennium Canon of Solar Eclipses, 2006), and their
    /// long-term parabola beyond. A few seconds off at most in the years the app shows, which moves
    /// the Moon by a few thousandths of a degree.
    static func deltaT(year y: Double) -> Double {
        switch y {
        case ..<1961:
            let u = (y - 1820) / 100
            return -20 + 32 * u * u
        case ..<1986:
            let t = y - 1975
            return 45.45 + 1.067 * t - t * t / 260 - t * t * t / 718
        case ..<2005:
            let t = y - 2000
            return 63.86 + 0.3345 * t - 0.060_374 * t * t + 0.001_727_5 * pow(t, 3)
                + 0.000_651_814 * pow(t, 4) + 0.000_023_735_99 * pow(t, 5)
        case ..<2050:
            let t = y - 2000
            return 62.92 + 0.322_17 * t + 0.005_589 * t * t
        case ..<2150:
            let u = (y - 1820) / 100
            return -20 + 32 * u * u - 0.5628 * (2150 - y)
        default:
            let u = (y - 1820) / 100
            return -20 + 32 * u * u
        }
    }
}
