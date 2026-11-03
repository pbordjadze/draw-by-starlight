import Foundation

/// The whole sky above a place, as a planisphere shows it: lying on your back with your head to
/// the north, the zenith in the middle, the horizon the rim, north up and east on the left. A
/// point's distance from the middle is its zenith distance over 90°, so the horizon is the unit
/// circle and a star below it falls outside.
public struct Dome: Sendable {
    public let place: Place
    /// The stars, precessed once to the evening (a few hours move them by far less than a point).
    let positions: [Int: Equatorial]
    let stars: [Star]

    /// The stars to `faintest`, and every star of the figures listed, precessed to `moment`.
    public init(catalogue: Catalogue, place: Place, around moment: JulianDay, faintest: Double = 5,
                figures: [Constellation] = []) {
        self.place = place
        let own = Set(figures.flatMap(\.stars))
        let chosen = catalogue.stars.values.filter { $0.magnitude <= faintest || own.contains($0.id) }
        stars = chosen.sorted { $0.magnitude > $1.magnitude }
        positions = Dictionary(uniqueKeysWithValues: chosen.map { ($0.id, $0.position(at: moment)) })
    }

    /// Where a direction falls on the dome.
    public static func point(_ direction: Horizontal) -> PlanePoint {
        let r = (90 - direction.altitude) / 90
        return PlanePoint(x: -r * sin(degrees: direction.azimuth), y: r * cos(degrees: direction.azimuth))
    }

    /// Where a star stands at `moment`, on the dome (outside the unit circle when it is down).
    public func point(of star: Int, at moment: JulianDay) -> PlanePoint? {
        positions[star].map { Self.point(place.horizontal(of: $0, at: moment)) }
    }

    /// The stars above the horizon at `moment`, faintest first, so the bright ones draw on top.
    public func visible(at moment: JulianDay) -> [FigureScene.PlacedStar] {
        let sidereal = place.siderealTime(at: moment)
        return stars.compactMap { star in
            guard let position = positions[star.id] else { return nil }
            let direction = position.horizontal(latitude: place.latitude, localSiderealTime: sidereal)
            guard direction.altitude > 0 else { return nil }
            return FigureScene.PlacedStar(star: star, point: Self.point(direction))
        }
    }
}
