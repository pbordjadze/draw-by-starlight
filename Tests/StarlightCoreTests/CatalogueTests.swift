import Foundation
import Testing
@testable import StarlightCore

/// The bundled sky against its sources: the Bright Star Catalogue's 9,096 stars (VizieR V/50),
/// the IAU's star names, the 88 constellations.
struct CatalogueTests {
    let catalogue = Catalogue.bundled

    @Test func everyStarOfTheBrightStarCatalogue() {
        // 9,110 numbers, 14 of them novae and galaxies kept only for the numbering.
        #expect(catalogue.stars.count == 9096)
        #expect(catalogue.stars[92] == nil)
    }

    @Test func betelgeuse() throws {
        // BSC5, HR 2061: 58 α Ori, 5h55m10.3s +7°24′25″, V 0.50, B−V 1.85.
        let star = try #require(catalogue.stars[2061])
        #expect(star.name == "Betelgeuse")
        #expect(star.designation == "α")
        #expect(star.constellation == "Ori")
        #expect(star.magnitude == 0.50)
        #expect(star.colorIndex == 1.85)
        #expect(abs(star.j2000.rightAscension - sexagesimal(5, 55, 10.3, hours: true)) < 1e-4)
        #expect(abs(star.j2000.declination - sexagesimal(7, 24, 25)) < 1e-4)
    }

    @Test func arcturusMoves() throws {
        // BSC5, HR 5340: proper motion −1.093″ and −1.998″ a year: in 26 years, about 59″ more than
        // precession alone moves it.
        let star = try #require(catalogue.stars[5340])
        #expect(star.properMotion.rightAscension == -1.093)
        #expect(star.properMotion.declination == -1.998)
        let later = JulianDay(JulianDay.j2000.value + 26 * 365.25)
        let precessedOnly = star.j2000.precessed(from: .j2000, to: later)
        #expect(abs(star.position(at: later).separation(from: precessedOnly) * 3600 - 59.3) < 0.5)
    }

    @Test func theNamedStars() {
        let named = catalogue.stars.values.filter { $0.name != nil }
        #expect(named.count == 333)
        #expect(catalogue.stars[424]?.name == "Polaris")
        #expect(catalogue.stars[7001]?.name == "Vega")
        #expect(catalogue.stars[2491]?.name == "Sirius")
    }

    @Test func the88Constellations() {
        #expect(catalogue.constellations.count == 88)
        #expect(catalogue.constellations["UMa"]?.name == "Ursa Major")
        #expect(catalogue.constellations["Ser"]?.border.count == 2)
        for constellation in catalogue.constellations.values {
            #expect(!constellation.lines.isEmpty, "\(constellation.id) has no figure")
            #expect(constellation.stars.allSatisfy { catalogue.stars[$0] != nil })
        }
    }

    @Test func cassiopeiasW() throws {
        // ε, δ, γ, α, β Cassiopeiae.
        let cassiopeia = try #require(catalogue.constellations["Cas"])
        #expect(cassiopeia.lines == [[542, 403, 264, 168, 21]])
        #expect(cassiopeia.stars.compactMap { catalogue.stars[$0]?.designation } == ["ε", "δ", "γ", "α", "β"])
        #expect(cassiopeia.segments.count == 4)
    }

    @Test func lyrasParallelogramIsDrawnOnce() throws {
        // Its lines pass through ζ1 twice; each segment counts once.
        let lyra = try #require(catalogue.constellations["Lyr"])
        let pairs = lyra.segments.map { Set([$0.0, $0.1]) }
        #expect(Set(pairs).count == pairs.count)
    }

    @Test func designatedStarsLieInsideTheirBorders() throws {
        // Delporte drew the borders around the stars' Bayer and Flamsteed designations.
        var outside: [Int] = [], total = 0
        for star in catalogue.stars.values {
            guard let id = star.constellation, let constellation = catalogue.constellations[id] else { continue }
            total += 1
            if !constellation.border.contains(where: { $0.encloses(star.j2000) }) { outside.append(star.id) }
        }
        #expect(total > 3000)
        #expect(outside.isEmpty, "outside their borders: \(outside)")
        for (number, id) in [(2061, "Ori"), (424, "UMi"), (7001, "Lyr"), (2491, "CMa"), (6527, "Sco"), (8425, "Gru")] {
            let border = try #require(catalogue.constellations[id]).border
            let star = try #require(catalogue.stars[number])
            #expect(border.contains { $0.encloses(star.j2000) }, "HR \(number) in \(id)")
        }
    }

    @Test func theBordersCloseAroundThePoles() throws {
        let northPole = Equatorial(rightAscension: 0, declination: 89.9)
        let southPole = Equatorial(rightAscension: 0, declination: -89.9)
        #expect(try #require(catalogue.constellations["UMi"]).border[0].encloses(northPole))
        #expect(try #require(catalogue.constellations["Oct"]).border[0].encloses(southPole))
        #expect(!(try #require(catalogue.constellations["Ori"]).border[0].encloses(northPole)))
    }
}

extension Array where Element == Equatorial {
    /// Whether this closed outline goes once around `point`: the winding number of its stereographic
    /// projection from the point's own direction, which any outline not reaching its antipode allows.
    func encloses(_ point: Equatorial) -> Bool {
        let projection = SkyProjection(center: Horizontal(altitude: point.declination, azimuth: point.rightAscension))
        let flat = map { projection.project(Horizontal(altitude: $0.declination, azimuth: $0.rightAscension)) }
        var turning = 0.0
        for (a, b) in zip(flat, flat.dropFirst() + flat.prefix(1)) {
            var step = atan2(b.y, b.x) - atan2(a.y, a.x)
            if step > .pi { step -= 2 * .pi }
            if step < -.pi { step += 2 * .pi }
            turning += step
        }
        return abs(turning) > .pi
    }
}
