import Foundation
import Testing
@testable import StarlightCore

/// The whole sky as a planisphere shows it: the zenith in the middle, the horizon the rim, north
/// up and east on the left.
struct DomeTests {
    @Test func theZenithIsTheMiddleAndTheHorizonTheRim() {
        let zenith = Dome.point(Horizontal(altitude: 90, azimuth: 123))
        #expect(abs(zenith.x) < 1e-12 && abs(zenith.y) < 1e-12)
        let north = Dome.point(Horizontal(altitude: 0, azimuth: 0))
        #expect(abs(north.x) < 1e-12 && abs(north.y - 1) < 1e-12)
        let east = Dome.point(Horizontal(altitude: 0, azimuth: 90))
        #expect(abs(east.x + 1) < 1e-12 && abs(east.y) < 1e-12)
    }

    @Test func venusOverWashington() {
        // Meeus 13.b (Astronomical Algorithms, 2nd ed., 1998): Venus 15.1249° up, 68.0337° west of
        // south, so in the dome's lower right, five sixths of the way out.
        let venus = Equatorial(rightAscension: sexagesimal(23, 9, 16.641, hours: true), declination: sexagesimal(-6, 43, 11.61))
        let local = sexagesimal(8, 34, 56.853, hours: true) - sexagesimal(77, 3, 56)
        let p = Dome.point(venus.horizontal(latitude: sexagesimal(38, 55, 17), localSiderealTime: local))
        #expect(abs((p.x * p.x + p.y * p.y).squareRoot() - (90 - 15.1249) / 90) < 1e-5)
        #expect(abs(atan2(p.x, -p.y) * 180 / .pi - 68.0337) < 1e-3)
    }

    @Test func polarisStandsAsHighAsTheLatitude() throws {
        // The pole stands as high as the latitude; Polaris is within a degree of it (Meeus ch. 21).
        let evening = try moment(2026, 10, 26, 1)
        let dome = Dome(catalogue: .bundled, place: Place(latitude: 40, longitude: -75), around: evening)
        let polaris = try #require(dome.point(of: 424, at: evening))
        #expect(abs(polaris.x) < 1 / 90.0)
        #expect(abs(polaris.y - 50 / 90.0) < 1 / 90.0)
        #expect(dome.visible(at: evening).contains { $0.star.id == 424 })
    }

    @Test func aFigureStarFainterThanTheCutIsKept() throws {
        let evening = try moment(2026, 10, 26, 1)
        let lyra = try #require(Catalogue.bundled.constellations["Lyr"])
        let dome = Dome(catalogue: .bundled, place: Place(latitude: 40, longitude: -75), around: evening, faintest: 1, figures: [lyra])
        for star in lyra.stars { #expect(dome.point(of: star, at: evening) != nil) }
        #expect(dome.visible(at: evening).allSatisfy { $0.star.magnitude <= 1 || lyra.stars.contains($0.star.id) })
    }
}
