import Foundation

/// One constellation laid out for drawing: its stars where they sit in the stargazer's sky at a
/// moment, up toward the zenith and turned as they would see them facing it, among the fainter
/// stars around them, with its border. Points are in degrees of sky (`SkyProjection`); the view
/// scales them to fit.
public struct FigureScene: Sendable {
    public struct PlacedStar: Sendable, Identifiable {
        public let star: Star
        public let point: PlanePoint
        public var id: Int { star.id }
    }

    /// Which moment the scene shows.
    public enum Timing: Sendable, Equatable {
        /// Now: the figure is up.
        case now
        /// The figure is below the horizon now; the scene shows it at its highest, when it crosses
        /// the meridian, at this moment (before the next sunrise).
        case later(JulianDay)
        /// The figure is below the horizon now and crosses the meridian in daylight; the scene
        /// shows it an hour before the next sunrise, at this moment.
        case beforeDawn(JulianDay)
        /// It never rises from here (or the place is unknown): the scene is north up instead.
        case unseen
    }

    public let constellation: Constellation
    public let moment: JulianDay
    public let timing: Timing
    /// Where the figure's middle stands at `moment`; nil when `timing` is `.unseen`.
    public let center: Horizontal?
    /// The figure's stars, in the order the figure's lines reach them.
    public let figure: [PlacedStar]
    /// The other stars around it, to magnitude 6.5, out to the frame's corners.
    public let backdrop: [PlacedStar]
    /// Its IAU border, as polylines on the plane.
    public let border: [[PlanePoint]]
    /// How far the figure's stars reach from the plane's origin, in degrees: the view fits this.
    public let span: Double
    /// When the figure's middle next crosses the meridian after `now`, its highest; nil without a
    /// place.
    public let transit: JulianDay?

    /// A figure whose middle is lower than this is not up: it is shown later, at its highest.
    static let horizon = 3.0

    /// `backdrop` false skips the surrounding stars (a list of standings needs none).
    public init(constellation: Constellation, catalogue: Catalogue, place: Place?, now: JulianDay, backdrop: Bool = true) {
        self.constellation = constellation
        let stars = constellation.stars.compactMap { catalogue.stars[$0] }
        let middleJ2000 = Self.middle(of: stars.map { $0.j2000 }) ?? Equatorial(rightAscension: 0, declination: 0)

        // The moment: now if the figure's middle is up, else its next meridian crossing, or an hour
        // before sunrise when the crossing comes in daylight.
        var moment = now
        var timing = Timing.unseen
        var transit: JulianDay?
        var direction: (Equatorial) -> Horizontal = { Horizontal(altitude: $0.declination, azimuth: -$0.rightAscension) }
        if let place {
            // Hour angle zero: the sidereal time equals the middle's right ascension.
            let wait = (middleJ2000.rightAscension - place.siderealTime(at: now)).normalizedDegrees / 360.985_647
            let crossing = JulianDay(now.value + wait)
            transit = crossing
            let middleAltitude = { (t: JulianDay) in place.horizontal(of: middleJ2000.precessed(from: .j2000, to: t), at: t).altitude }
            let sunrise = place.nextRise(of: .sun, after: now)
            if middleAltitude(now) >= Self.horizon {
                timing = .now
            } else if let sunrise, crossing > sunrise {
                let beforeDawn = JulianDay(sunrise.value - 1 / 24)
                if beforeDawn > now, middleAltitude(beforeDawn) >= Self.horizon {
                    moment = beforeDawn
                    timing = .beforeDawn(beforeDawn)
                }
            } else if middleAltitude(crossing) >= Self.horizon {
                moment = crossing
                timing = .later(crossing)
            }
            if timing != .unseen {
                let t = moment
                direction = { place.horizontal(of: $0, at: t) }
            }
        }
        self.moment = moment
        self.timing = timing
        self.transit = transit

        let figureDirections = stars.map { direction($0.position(at: moment)) }
        let projection = SkyProjection(centeredOn: figureDirections) ?? SkyProjection(center: Horizontal(altitude: 0, azimuth: 0))
        center = timing == .unseen ? nil : projection.center
        figure = zip(stars, figureDirections).map { PlacedStar(star: $0, point: projection.project($1)) }
        let span = figure.map { ($0.point.x * $0.point.x + $0.point.y * $0.point.y).squareRoot() }.max() ?? 1
        self.span = max(span, 1)

        // The backdrop: everything within the frame's corners (a portrait frame fitted to the
        // span reaches about twice it), found cheaply at J2000 first.
        let reach = 2.2 * self.span + 1
        let own = Set(constellation.stars)
        self.backdrop = !backdrop ? [] : catalogue.stars.values
            .filter { !own.contains($0.id) && $0.magnitude <= 6.5 && $0.j2000.separation(from: middleJ2000) <= reach + 1 }
            .map { PlacedStar(star: $0, point: projection.project(direction($0.position(at: moment)))) }
            .filter { ($0.point.x * $0.point.x + $0.point.y * $0.point.y).squareRoot() <= reach }
            .sorted { $0.star.id < $1.star.id }
        border = constellation.border.map { outline in
            outline.map { projection.project(direction($0.precessed(from: .j2000, to: moment))) }
        }
    }

    /// The direction in the middle of `directions` (the mean of their unit vectors).
    public static func middle(of directions: [Equatorial]) -> Equatorial? {
        var x = 0.0, y = 0.0, z = 0.0
        for d in directions {
            x += cos(degrees: d.declination) * cos(degrees: d.rightAscension)
            y += cos(degrees: d.declination) * sin(degrees: d.rightAscension)
            z += sin(degrees: d.declination)
        }
        let length = (x * x + y * y + z * z).squareRoot()
        guard length > 1e-9 else { return nil }
        return Equatorial(rightAscension: atan2Degrees(y, x), declination: asinDegrees(z / length))
    }
}
