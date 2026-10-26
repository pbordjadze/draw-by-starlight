import Foundation

/// A direction on the sky by right ascension and declination, in degrees, for an equator and
/// equinox the caller knows (the catalogue's are J2000's).
public struct Equatorial: Sendable, Hashable {
    /// In [0, 360).
    public let rightAscension: Double
    public let declination: Double

    public init(rightAscension: Double, declination: Double) {
        self.rightAscension = rightAscension.normalizedDegrees
        self.declination = declination
    }

    /// The angle between two directions, in degrees.
    public func separation(from other: Equatorial) -> Double {
        acosDegrees(sin(degrees: declination) * sin(degrees: other.declination)
            + cos(degrees: declination) * cos(degrees: other.declination)
            * cos(degrees: rightAscension - other.rightAscension))
    }

    /// Where this direction stands for an observer at `latitude` when the local sidereal time is
    /// `localSiderealTime` (Meeus, *Astronomical Algorithms*, 13.5 and 13.6), without refraction.
    func horizontal(latitude: Double, localSiderealTime: Double) -> Horizontal {
        let hourAngle = localSiderealTime - rightAscension
        let fromSouth = atan2Degrees(
            sin(degrees: hourAngle),
            cos(degrees: hourAngle) * sin(degrees: latitude) - tan(degrees: declination) * cos(degrees: latitude))
        let altitude = asinDegrees(sin(degrees: latitude) * sin(degrees: declination)
            + cos(degrees: latitude) * cos(degrees: declination) * cos(degrees: hourAngle))
        return Horizontal(altitude: altitude, azimuth: fromSouth + 180)
    }
}

/// A direction in an observer's sky: altitude above the horizon and azimuth, in degrees. Azimuth
/// runs from north through east, as a compass reads (0 north, 90 east).
public struct Horizontal: Sendable, Hashable {
    public let altitude: Double
    /// In [0, 360).
    public let azimuth: Double

    public init(altitude: Double, azimuth: Double) {
        self.altitude = altitude
        self.azimuth = azimuth.normalizedDegrees
    }
}

/// Where the stargazer stands: geographic latitude and longitude in degrees, longitude positive
/// east of Greenwich. All the sky's math needs.
public struct Place: Sendable, Hashable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// The local mean sidereal time, in degrees.
    public func siderealTime(at moment: JulianDay) -> Double {
        (moment.greenwichMeanSiderealTime + longitude).normalizedDegrees
    }

    /// Where a direction, given at the equator and equinox of `moment`, stands in this place's sky
    /// then, without refraction.
    public func horizontal(of direction: Equatorial, at moment: JulianDay) -> Horizontal {
        direction.horizontal(latitude: latitude, localSiderealTime: siderealTime(at: moment))
    }
}
