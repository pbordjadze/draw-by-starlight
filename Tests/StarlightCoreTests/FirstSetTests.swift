import Foundation
import Testing
@testable import StarlightCore

/// The constellations that can be drawn: each in the catalogue, each with its Wikipedia story and
/// a label for every star; a place for the device's time zone.
struct FirstSetTests {
    let catalogue = Catalogue.bundled
    let stories = Stories.bundled

    @Test func everyFigureIsInTheCatalogueWithItsStory() throws {
        #expect(Catalogue.firstSet.count == 16)
        for id in Catalogue.firstSet {
            let constellation = try #require(catalogue.constellations[id], "\(id)")
            #expect(constellation.segments.count >= 3, "\(id)")
            let story = try #require(stories[id], "\(id)")
            #expect(!story.paragraphs.isEmpty && story.paragraphs.allSatisfy { $0.count > 40 }, "\(id)")
            #expect(story.url.host == "en.wikipedia.org", "\(id)")
            #expect(story.revision > 1_000_000_000, "\(id)")
            // Every star of the figure can be named on the drawing.
            for star in constellation.stars {
                #expect(try #require(catalogue.stars[star]).label.isEmpty == false)
            }
        }
    }

    @Test func theStoriesSayWhereTheyComeFrom() throws {
        #expect(stories.source.hasPrefix("Wikipedia"))
        #expect(stories.license.contains("Attribution-ShareAlike 4.0"))
        #expect(stories.licenseURL.absoluteString == "https://creativecommons.org/licenses/by-sa/4.0/")
        let cassiopeia = try #require(stories["Cas"])
        #expect(cassiopeia.title == "Cassiopeia (constellation)")
        #expect(cassiopeia.url.absoluteString == "https://en.wikipedia.org/wiki/Cassiopeia_(constellation)")
        #expect(cassiopeia.permalink.absoluteString
            == "https://en.wikipedia.org/w/index.php?title=Cassiopeia_(constellation)&oldid=\(cassiopeia.revision)")
        #expect(cassiopeia.paragraphs[0].hasPrefix("Cassiopeia is a constellation"))
    }

    @Test func starLabels() throws {
        #expect(try #require(catalogue.stars[168]).label == "Schedar")
        #expect(try #require(catalogue.stars[264]).label == "γ")
        #expect(Star(id: 7, j2000: Equatorial(rightAscension: 0, declination: 0), properMotion: (0, 0), magnitude: 6,
                     colorIndex: nil, designation: nil, constellation: nil, name: nil).label == "HR 7")
    }

    @Test func aPlaceFromTheTimeZone() throws {
        // zone1970.tab: America/New_York +404251-0740023.
        let newYork = try #require(Place.guess(timeZone: TimeZone(identifier: "America/New_York")!))
        #expect(abs(newYork.latitude - 40.7142) < 1e-3 && abs(newYork.longitude - -74.0064) < 1e-3)
        let auckland = try #require(Place.guess(timeZone: TimeZone(identifier: "Pacific/Auckland")!))
        #expect(auckland.latitude < 0 && auckland.longitude > 170)
        #expect(Place.guess(timeZone: TimeZone(secondsFromGMT: 3600)!) == nil)
        #expect(Place.zones.count > 300)
    }
}
