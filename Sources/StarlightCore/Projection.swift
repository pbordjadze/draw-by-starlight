import Foundation

/// A point on a drawing of the sky, in degrees of sky across: x to the right, y up.
public struct PlanePoint: Sendable, Hashable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// Lays a patch of an observer's sky flat for drawing, as they see it facing its center: up
/// toward the zenith, right the way the sky turns from left to right in front of them. The
/// stereographic projection, which keeps the figures' shapes; near the center a degree on the sky
/// is a degree on the plane.
public struct SkyProjection: Sendable {
    /// The direction drawn at the plane's origin.
    public let center: Horizontal

    public init(center: Horizontal) {
        self.center = center
    }

    /// A projection centered on the middle of `directions` (the mean of their unit vectors).
    public init?(centeredOn directions: [Horizontal]) {
        var x = 0.0, y = 0.0, z = 0.0
        for d in directions {
            x += cos(degrees: d.altitude) * cos(degrees: d.azimuth)
            y += cos(degrees: d.altitude) * sin(degrees: d.azimuth)
            z += sin(degrees: d.altitude)
        }
        let length = (x * x + y * y + z * z).squareRoot()
        guard length > 1e-9 else { return nil }
        center = Horizontal(altitude: asinDegrees(z / length), azimuth: atan2Degrees(y, x))
    }

    /// Where `direction` falls on the plane. The point opposite the center has no place: it comes
    /// back far out, never as a number that isn't one.
    public func project(_ direction: Horizontal) -> PlanePoint {
        let across = direction.azimuth - center.azimuth
        let cosine = sin(degrees: center.altitude) * sin(degrees: direction.altitude)
            + cos(degrees: center.altitude) * cos(degrees: direction.altitude) * cos(degrees: across)
        let k = 2 / max(1 + cosine, 1e-12) * 180 / .pi
        return PlanePoint(
            x: k * cos(degrees: direction.altitude) * sin(degrees: across),
            y: k * (cos(degrees: center.altitude) * sin(degrees: direction.altitude)
                - sin(degrees: center.altitude) * cos(degrees: direction.altitude) * cos(degrees: across)))
    }
}
