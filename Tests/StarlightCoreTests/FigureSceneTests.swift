import Foundation
import Testing
@testable import StarlightCore

/// Figures laid out for drawing, pinned to an ephemeris (PyEphem) for 40° N, 75° W on 2026
/// October 25 at 9:00 PM EDT (01:00 UT October 26): Cassiopeia's stars stood 51 to 64° up at
/// azimuth 33 to 42°, Cygnus's 54 to 74° up at 238 to 309°, and Betelgeuse rose at 10:11 PM.
struct FigureSceneTests {
    let catalogue = Catalogue.bundled
    let pennsylvania = Place(latitude: 40, longitude: -75)
    let evening = try! moment(2026, 10, 26, 1)

    func scene(_ id: String, at when: JulianDay? = nil, place: Place? = Place(latitude: 40, longitude: -75)) -> FigureScene {
        FigureScene(constellation: catalogue.constellations[id]!, catalogue: catalogue, place: place, now: when ?? evening)
    }

    @Test func cassiopeiaHighInTheNortheast() throws {
        let cas = scene("Cas")
        #expect(cas.timing == .now)
        let center = try #require(cas.center)
        #expect(center.altitude > 51 && center.altitude < 64)
        #expect(center.azimuth > 33 && center.azimuth < 42)
        #expect(cas.figure.map(\.id) == [542, 403, 264, 168, 21])
        // Up is up: Segin (ε, HR 542), the highest star that evening, is the highest point.
        let highest = cas.figure.max { $0.point.y < $1.point.y }!
        let altitudes = cas.figure.map { pennsylvania.horizontal(of: $0.star.position(at: evening), at: evening).altitude }
        #expect(highest.id == cas.figure[altitudes.firstIndex(of: altitudes.max()!)!].id)
        #expect(cas.span > 5 && cas.span < 10)
        #expect(cas.border.count == 1 && cas.border[0].count > 20)
    }

    @Test func cygnusHighInTheWest() throws {
        let cyg = scene("Cyg")
        #expect(cyg.timing == .now)
        let center = try #require(cyg.center)
        #expect(center.altitude > 54 && center.altitude < 74)
        #expect(center.azimuth > 238 && center.azimuth < 309)
    }

    @Test func orionComesLater() throws {
        // Below the horizon at 9 PM (Betelgeuse rises at 10:11 PM): shown at its meridian crossing,
        // in the small hours, due south.
        let ori = scene("Ori")
        guard case .later(let transit) = ori.timing else { Issue.record("Orion should be shown later"); return }
        let hours = (transit.value - evening.value) * 24
        #expect(hours > 5 && hours < 9)
        let center = try #require(ori.center)
        #expect(center.altitude > 40 && abs(center.azimuth - 180) < 2)
        #expect(ori.moment == transit)
        #expect(ori.transit == transit)
    }

    @Test func aStandingNeedsNoBackdrop() throws {
        let cas = FigureScene(constellation: catalogue.constellations["Cas"]!, catalogue: catalogue,
                              place: pennsylvania, now: evening, backdrop: false)
        #expect(cas.backdrop.isEmpty && cas.timing == .now)
        // Cassiopeia crosses the meridian (due north, above the pole) later that night.
        let transit = try #require(cas.transit)
        let hours = (transit.value - evening.value) * 24
        #expect(hours > 2 && hours < 4)
        #expect(cas.transit != nil && cas.center != nil)
    }

    @Test func ursaMajorComesBeforeDawn() throws {
        // At 9 PM the Great Bear is at its lowest, its middle on the northern horizon, and it
        // crosses the meridian after sunrise: shown an hour before sunrise, high in the northeast.
        let uma = scene("UMa")
        guard case .beforeDawn(let moment) = uma.timing else { Issue.record("Ursa Major should be shown before dawn"); return }
        let center = try #require(uma.center)
        #expect(center.altitude > 40, "\(center)")
        #expect(center.azimuth > 20 && center.azimuth < 90, "\(center)")
        #expect((moment.value - evening.value) * 24 > 9)
    }

    @Test func leoComesBeforeDawn() throws {
        // Leo rises after midnight and crosses the meridian in daylight (sunrise is about 7:25 AM
        // EDT): shown an hour before sunrise, halfway up in the east.
        let leo = scene("Leo")
        guard case .beforeDawn(let moment) = leo.timing else { Issue.record("Leo should be shown before dawn"); return }
        let hours = (moment.value - evening.value) * 24
        #expect(hours > 9 && hours < 10)
        let center = try #require(leo.center)
        #expect(center.altitude > 30, "\(center)")
        #expect(center.azimuth > 90 && center.azimuth < 150, "\(center)")
        #expect(try #require(leo.transit) > moment)
    }

    @Test func theSouthernCrossNeverRisesFromPennsylvania() {
        let cru = scene("Cru")
        #expect(cru.timing == .unseen)
        #expect(cru.center == nil)
        #expect(cru.figure.count == 4)
    }

    @Test func noPlaceMeansNorthUp() throws {
        let cas = scene("Cas", place: nil)
        #expect(cas.timing == .unseen)
        // North up, east left: Caph (β, RA 2.3°) sits right of Segin (ε, RA 28.6°).
        let caph = try #require(cas.figure.first { $0.id == 21 })
        let segin = try #require(cas.figure.first { $0.id == 542 })
        #expect(caph.point.x > segin.point.x)
    }

    @Test func theBackdropSurroundsTheFigure() {
        let cas = scene("Cas")
        #expect(cas.backdrop.count > 100 && cas.backdrop.count < 1500)
        #expect(cas.backdrop.allSatisfy { !cas.constellation.stars.contains($0.id) && $0.star.magnitude <= 6.5 })
        let reach = 2.2 * cas.span + 1
        #expect(cas.backdrop.allSatisfy { ($0.point.x * $0.point.x + $0.point.y * $0.point.y).squareRoot() <= reach })
        // Ruchbah's neighbour χ Cas (HR 442, magnitude 4.7) is among them.
        #expect(cas.backdrop.contains { $0.id == 442 })
    }
}
