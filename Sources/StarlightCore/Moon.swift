import Foundation

/// The Moon's place, distance and phase, to about ten arcseconds in place (Meeus, *Astronomical
/// Algorithms*, chapter 47, from the ELP-2000/82 theory, and chapter 48).
public struct Moon: Sendable {
    /// Its geocentric ecliptic longitude and latitude for the mean equinox of the date, in degrees.
    let longitude: Double
    let latitude: Double
    /// Its apparent ecliptic longitude (nutation applied), in degrees.
    let apparentLongitude: Double
    /// Its geocentric apparent right ascension and declination, for the true equator and equinox
    /// of the date.
    public let position: Equatorial
    /// The distance between the Earth's and the Moon's centers, in kilometers.
    public let distance: Double
    /// The angle between the Sun and the Earth seen from the Moon, in degrees: 0 full, 180 new.
    public let phaseAngle: Double
    /// True from new to full, false from full to new.
    public let isWaxing: Bool

    /// The Moon at a moment (Universal Time).
    public init(at moment: JulianDay) {
        self.init(ephemeris: moment.ephemeris)
    }

    init(ephemeris jde: JulianDay) {
        let t = jde.centuriesSinceJ2000
        let meanLongitude = 218.316_447_7 + 481_267.881_234_21 * t - 0.001_578_6 * t * t
            + t * t * t / 538_841 - t * t * t * t / 65_194_000
        let elongation = 297.850_192_1 + 445_267.111_403_4 * t - 0.001_881_9 * t * t
            + t * t * t / 545_868 - t * t * t * t / 113_065_000
        let sunAnomaly = 357.529_109_2 + 35_999.050_290_9 * t - 0.000_153_6 * t * t + t * t * t / 24_490_000
        let moonAnomaly = 134.963_396_4 + 477_198.867_505_5 * t + 0.008_741_4 * t * t
            + t * t * t / 69_699 - t * t * t * t / 14_712_000
        let argument = 93.272_095_0 + 483_202.017_523_3 * t - 0.003_653_9 * t * t
            - t * t * t / 3_526_000 + t * t * t * t / 863_310_000
        let a1 = 119.75 + 131.849 * t
        let a2 = 53.09 + 479_264.290 * t
        let a3 = 313.45 + 481_266.484 * t
        let e = 1 - 0.002_516 * t - 0.000_007_4 * t * t

        func angle(_ term: Term) -> Double {
            term.d * elongation + term.m * sunAnomaly + term.mPrime * moonAnomaly + term.f * argument
        }
        // Terms with the Sun's anomaly shrink with the Earth's orbit's eccentricity.
        func eccentricity(_ term: Term) -> Double {
            switch abs(term.m) { case 1: e; case 2: e * e; default: 1 }
        }

        var sumL = 0.0, sumR = 0.0, sumB = 0.0
        for term in Self.longitudeAndDistance {
            let factor = eccentricity(term)
            sumL += term.coefficient * factor * sin(degrees: angle(term))
            sumR += term.distance * factor * cos(degrees: angle(term))
        }
        for term in Self.latitude {
            sumB += term.coefficient * eccentricity(term) * sin(degrees: angle(term))
        }
        sumL += 3958 * sin(degrees: a1) + 1962 * sin(degrees: meanLongitude - argument) + 318 * sin(degrees: a2)
        sumB += -2235 * sin(degrees: meanLongitude) + 382 * sin(degrees: a3)
            + 175 * sin(degrees: a1 - argument) + 175 * sin(degrees: a1 + argument)
            + 127 * sin(degrees: meanLongitude - moonAnomaly) - 115 * sin(degrees: meanLongitude + moonAnomaly)

        longitude = (meanLongitude + sumL / 1_000_000).normalizedDegrees
        latitude = sumB / 1_000_000
        distance = 385_000.56 + sumR / 1000
        let nutation = Nutation(jde)
        apparentLongitude = longitude + nutation.longitude
        position = Equatorial(eclipticLongitude: apparentLongitude, latitude: latitude, obliquity: nutation.trueObliquity)

        // Meeus 48.2 and 48.3: the phase angle from the Moon's elongation from the Sun.
        let sun = Sun(ephemeris: jde)
        let sunDistance = sun.distance * 149_597_870.7
        let fromSun = acosDegrees(cos(degrees: latitude) * cos(degrees: apparentLongitude - sun.apparentLongitude))
        phaseAngle = atan2Degrees(sunDistance * sin(degrees: fromSun), distance - sunDistance * cos(degrees: fromSun))
        isWaxing = (apparentLongitude - sun.apparentLongitude).normalizedDegrees < 180
    }

    /// The fraction of its disk the Sun lights, from 0 (new) to 1 (full).
    public var illuminatedFraction: Double { (1 + cos(degrees: phaseAngle)) / 2 }

    /// Its equatorial horizontal parallax, in degrees: how far it shifts between the Earth's
    /// center and a horizon.
    public var parallax: Double { asinDegrees(6378.14 / distance) }

    /// Where it stands in `place`'s sky, seen from there rather than from the Earth's center
    /// (parallax lowers it by up to a degree), without refraction.
    public func horizontal(in place: Place, at moment: JulianDay) -> Horizontal {
        let geocentric = place.horizontal(of: position, at: moment)
        return Horizontal(
            altitude: geocentric.altitude - parallax * cos(degrees: geocentric.altitude),
            azimuth: geocentric.azimuth)
    }

    /// The Moon's four principal phases, by the excess of its apparent longitude over the Sun's.
    public enum Phase: Double, Sendable, CaseIterable {
        case new = 0, firstQuarter = 90, full = 180, lastQuarter = 270
    }

    /// The first moment after `moment` at which the Moon is at `phase`.
    public static func next(_ phase: Phase, after moment: JulianDay) -> JulianDay {
        // The excess grows by 12.19° a day on average; Newton's steps on it converge in a few.
        let synodicRate = 360 / 29.530_588_861
        func excess(_ t: JulianDay) -> Double {
            let jde = t.ephemeris
            return Moon(ephemeris: jde).apparentLongitude - Sun(ephemeris: jde).apparentLongitude
        }
        var t = JulianDay(moment.value + (phase.rawValue - excess(moment)).normalizedDegrees / synodicRate)
        for _ in 0..<8 {
            let step = (phase.rawValue - excess(t)).signedDegrees / synodicRate
            t = JulianDay(t.value + step)
            if abs(step) < 1e-6 { break }
        }
        return t
    }

    struct Term {
        let d: Double, m: Double, mPrime: Double, f: Double
        /// Σl's or Σb's coefficient, in millionths of a degree.
        let coefficient: Double
        /// Σr's coefficient, in meters.
        let distance: Double

        init(_ d: Double, _ m: Double, _ mPrime: Double, _ f: Double, _ coefficient: Double, _ distance: Double = 0) {
            self.d = d
            self.m = m
            self.mPrime = mPrime
            self.f = f
            self.coefficient = coefficient
            self.distance = distance
        }
    }

    /// Meeus's table 47.A: the periodic terms of the Moon's longitude (Σl) and distance (Σr).
    static let longitudeAndDistance: [Term] = [
        Term(0, 0, 1, 0, 6_288_774, -20_905_355), Term(2, 0, -1, 0, 1_274_027, -3_699_111),
        Term(2, 0, 0, 0, 658_314, -2_955_968), Term(0, 0, 2, 0, 213_618, -569_925),
        Term(0, 1, 0, 0, -185_116, 48_888), Term(0, 0, 0, 2, -114_332, -3149),
        Term(2, 0, -2, 0, 58793, 246_158), Term(2, -1, -1, 0, 57066, -152_138),
        Term(2, 0, 1, 0, 53322, -170_733), Term(2, -1, 0, 0, 45758, -204_586),
        Term(0, 1, -1, 0, -40923, -129_620), Term(1, 0, 0, 0, -34720, 108_743),
        Term(0, 1, 1, 0, -30383, 104_755), Term(2, 0, 0, -2, 15327, 10321),
        Term(0, 0, 1, 2, -12528, 0), Term(0, 0, 1, -2, 10980, 79661),
        Term(4, 0, -1, 0, 10675, -34782), Term(0, 0, 3, 0, 10034, -23210),
        Term(4, 0, -2, 0, 8548, -21636), Term(2, 1, -1, 0, -7888, 24208),
        Term(2, 1, 0, 0, -6766, 30824), Term(1, 0, -1, 0, -5163, -8379),
        Term(1, 1, 0, 0, 4987, -16675), Term(2, -1, 1, 0, 4036, -12831),
        Term(2, 0, 2, 0, 3994, -10445), Term(4, 0, 0, 0, 3861, -11650),
        Term(2, 0, -3, 0, 3665, 14403), Term(0, 1, -2, 0, -2689, -7003),
        Term(2, 0, -1, 2, -2602, 0), Term(2, -1, -2, 0, 2390, 10056),
        Term(1, 0, 1, 0, -2348, 6322), Term(2, -2, 0, 0, 2236, -9884),
        Term(0, 1, 2, 0, -2120, 5751), Term(0, 2, 0, 0, -2069, 0),
        Term(2, -2, -1, 0, 2048, -4950), Term(2, 0, 1, -2, -1773, 4130),
        Term(2, 0, 0, 2, -1595, 0), Term(4, -1, -1, 0, 1215, -3958),
        Term(0, 0, 2, 2, -1110, 0), Term(3, 0, -1, 0, -892, 3258),
        Term(2, 1, 1, 0, -810, 2616), Term(4, -1, -2, 0, 759, -1897),
        Term(0, 2, -1, 0, -713, -2117), Term(2, 2, -1, 0, -700, 2354),
        Term(2, 1, -2, 0, 691, 0), Term(2, -1, 0, -2, 596, 0),
        Term(4, 0, 1, 0, 549, -1423), Term(0, 0, 4, 0, 537, -1117),
        Term(4, -1, 0, 0, 520, -1571), Term(1, 0, -2, 0, -487, -1739),
        Term(2, 1, 0, -2, -399, 0), Term(0, 0, 2, -2, -381, -4421),
        Term(1, 1, 1, 0, 351, 0), Term(3, 0, -2, 0, -340, 0),
        Term(4, 0, -3, 0, 330, 0), Term(2, -1, 2, 0, 327, 0),
        Term(0, 2, 1, 0, -323, 1165), Term(1, 1, -1, 0, 299, 0),
        Term(2, 0, 3, 0, 294, 0), Term(2, 0, -1, -2, 0, 8752),
    ]

    /// Meeus's table 47.B: the periodic terms of the Moon's latitude (Σb).
    static let latitude: [Term] = [
        Term(0, 0, 0, 1, 5_128_122), Term(0, 0, 1, 1, 280_602), Term(0, 0, 1, -1, 277_693),
        Term(2, 0, 0, -1, 173_237), Term(2, 0, -1, 1, 55413), Term(2, 0, -1, -1, 46271),
        Term(2, 0, 0, 1, 32573), Term(0, 0, 2, 1, 17198), Term(2, 0, 1, -1, 9266),
        Term(0, 0, 2, -1, 8822), Term(2, -1, 0, -1, 8216), Term(2, 0, -2, -1, 4324),
        Term(2, 0, 1, 1, 4200), Term(2, 1, 0, -1, -3359), Term(2, -1, -1, 1, 2463),
        Term(2, -1, 0, 1, 2211), Term(2, -1, -1, -1, 2065), Term(0, 1, -1, -1, -1870),
        Term(4, 0, -1, -1, 1828), Term(0, 1, 0, 1, -1794), Term(0, 0, 0, 3, -1749),
        Term(0, 1, -1, 1, -1565), Term(1, 0, 0, 1, -1491), Term(0, 1, 1, 1, -1475),
        Term(0, 1, 1, -1, -1410), Term(0, 1, 0, -1, -1344), Term(1, 0, 0, -1, -1335),
        Term(0, 0, 3, 1, 1107), Term(4, 0, 0, -1, 1021), Term(4, 0, -1, 1, 833),
        Term(0, 0, 1, -3, 777), Term(4, 0, -2, 1, 671), Term(2, 0, 0, -3, 607),
        Term(2, 0, 2, -1, 596), Term(2, -1, 1, -1, 491), Term(2, 0, -2, 1, -451),
        Term(0, 0, 3, -1, 439), Term(2, 0, 2, 1, 422), Term(2, 0, -3, -1, 421),
        Term(2, 1, -1, 1, -366), Term(2, 1, 0, 1, -351), Term(4, 0, 0, 1, 331),
        Term(2, -1, 1, 1, 315), Term(2, -2, 0, -1, 302), Term(0, 0, 1, 3, -283),
        Term(2, 1, 1, -1, -229), Term(1, 1, 0, -1, 223), Term(1, 1, 0, 1, 223),
        Term(0, 1, -2, -1, -220), Term(2, 1, -1, -1, -220), Term(1, 0, 1, 1, -185),
        Term(2, -1, -2, -1, 181), Term(0, 1, 2, 1, -177), Term(4, 0, -2, -1, 176),
        Term(4, -1, -1, -1, 166), Term(1, 0, 1, -1, -164), Term(4, 0, 1, -1, 132),
        Term(1, 0, -1, -1, -119), Term(4, -1, 0, -1, 115), Term(2, -2, 0, 1, 107),
    ]
}
