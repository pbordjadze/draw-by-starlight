import Foundation
import Testing
@testable import StarlightCore

/// The drawing's projection: the stereographic projection's own geometry, and up as the observer
/// sees it.
struct ProjectionTests {
    let projection = SkyProjection(center: Horizontal(altitude: 40, azimuth: 180))

    @Test func theCenterIsTheOrigin() {
        let p = projection.project(projection.center)
        #expect(abs(p.x) < 1e-12 && abs(p.y) < 1e-12)
    }

    @Test func upIsTowardTheZenith() {
        let p = projection.project(Horizontal(altitude: 41, azimuth: 180))
        #expect(abs(p.x) < 1e-9)
        #expect(abs(p.y - 1) < 1e-4)
    }

    @Test func facingSouthEastIsOnTheLeft() {
        #expect(projection.project(Horizontal(altitude: 40, azimuth: 170)).x < 0)
        let north = SkyProjection(center: Horizontal(altitude: 40, azimuth: 0))
        #expect(north.project(Horizontal(altitude: 40, azimuth: 10)).x > 0)
    }

    @Test func distanceFromTheCenterIsTwiceTheTangentOfHalfTheAngle() {
        // The stereographic projection's radial law, r = 2 tan(c / 2), in radians.
        let direction = Horizontal(altitude: 55, azimuth: 200)
        let angle = Equatorial(rightAscension: 200, declination: 55)
            .separation(from: Equatorial(rightAscension: 180, declination: 40))
        let p = projection.project(direction)
        let radius = (p.x * p.x + p.y * p.y).squareRoot() * .pi / 180
        #expect(abs(radius - 2 * tan(angle * .pi / 360)) < 1e-9)
    }

    @Test func centeredOnAFigure() throws {
        let stars = [Horizontal(altitude: 50, azimuth: 30), Horizontal(altitude: 60, azimuth: 40)]
        let centered = try #require(SkyProjection(centeredOn: stars))
        #expect(centered.center.altitude > 50 && centered.center.altitude < 60)
        let points = stars.map(centered.project)
        #expect(points[1].y > points[0].y)
        #expect(SkyProjection(centeredOn: []) == nil)
    }
}
