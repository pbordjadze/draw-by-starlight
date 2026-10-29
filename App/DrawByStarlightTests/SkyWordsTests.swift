import Foundation
import StarlightCore
import Testing
@testable import DrawByStarlight

/// The words for where a figure stands, on the evening the core's tests pin (2026 October 25,
/// 9:00 PM EDT, 40° N 75° W).
@MainActor
struct SkyWordsTests {
    let sky = Sky(place: Place(latitude: 40, longitude: -75), now: Date(timeIntervalSince1970: 1_792_976_400),
                  timeZone: TimeZone(identifier: "America/New_York")!)

    @Test func compassAndHeight() {
        #expect(SkyWords.direction(azimuth: 0) == "north")
        #expect(SkyWords.direction(azimuth: 359) == "north")
        #expect(SkyWords.direction(azimuth: 37) == "northeast")
        #expect(SkyWords.direction(azimuth: 180) == "south")
        #expect(SkyWords.direction(azimuth: 300) == "northwest")
        #expect(SkyWords.direction(azimuth: 292) == "west")
        #expect(SkyWords.height(altitude: 64) == "high")
        #expect(SkyWords.height(altitude: 40) == "halfway up")
        #expect(SkyWords.height(altitude: 10) == "low")
    }

    @Test func cassiopeiaTonight() throws {
        let scene = sky.scene(try #require(sky.constellation("Cas")), backdrop: false)
        #expect(SkyWords.standing(scene, place: sky.place, time: sky.time) == "Turned as it sits tonight, high in the northeast.")
        #expect(SkyWords.listing(scene, place: sky.place, time: sky.time) == "High in the northeast")
    }

    @Test func orionLater() throws {
        let scene = sky.scene(try #require(sky.constellation("Ori")), backdrop: false)
        let standing = SkyWords.standing(scene, place: sky.place, time: sky.time)
        #expect(standing.hasPrefix("Below the horizon now. Turned as it will sit at 4:07"))
        // iOS sets a narrow space before AM.
        #expect(standing.contains("AM, high in the south."))
        #expect(SkyWords.listing(scene, place: sky.place, time: sky.time).hasPrefix("Rises later; highest at "))
    }

    @Test func leoBeforeDawn() throws {
        let scene = sky.scene(try #require(sky.constellation("Leo")), backdrop: false)
        let listing = SkyWords.listing(scene, place: sky.place, time: sky.time)
        #expect(listing.hasPrefix("Rises later; before dawn at 6:2"))
        #expect(SkyWords.standing(scene, place: sky.place, time: sky.time).hasPrefix("Below the horizon now. Turned as it will sit at 6:2"))
    }

    @Test func noPlace() throws {
        let nowhere = Sky(place: nil, now: sky.now, timeZone: sky.timeZone)
        let scene = nowhere.scene(try #require(nowhere.constellation("Cas")), backdrop: false)
        #expect(SkyWords.standing(scene, place: nil, time: nowhere.time) == "North is up.")
        #expect(SkyWords.listing(scene, place: nil, time: nowhere.time) == "Place unknown")
    }

    @Test func theDrawableListIsTheFirstSet() {
        #expect(sky.drawable.map(\.id) == Catalogue.firstSet)
        #expect(sky.stories["Ori"] != nil)
    }
}
