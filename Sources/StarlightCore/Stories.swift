import Foundation

/// What is said about a constellation when its figure is whole: the lead section of its English
/// Wikipedia article, word for word, with where it came from. The app writes no story of its own.
public struct Story: Sendable, Hashable, Decodable {
    /// The article's title ("Cassiopeia (constellation)").
    public let title: String
    /// The article.
    public let url: URL
    /// The revision quoted, and when it was made: `permalink` shows exactly that text.
    public let revision: Int
    public let revised: Date
    /// The lead section's paragraphs, as plain text.
    public let paragraphs: [String]

    /// The exact revision quoted, for anyone checking the words against their source.
    public var permalink: URL {
        var components = URLComponents(string: "https://en.wikipedia.org/w/index.php")!
        components.queryItems = [URLQueryItem(name: "title", value: title.replacingOccurrences(of: " ", with: "_")),
                                 URLQueryItem(name: "oldid", value: String(revision))]
        return components.url!
    }
}

/// The bundled stories (`Resources/stories.json`, written by `tools/wikipedia_stories.py`), and
/// the terms they are quoted under.
public struct Stories: Sendable, Decodable {
    public let source: String
    public let license: String
    public let licenseURL: URL
    /// The day the articles were read.
    public let retrieved: String
    /// By IAU abbreviation.
    public let stories: [String: Story]

    public static let bundled: Stories = {
        guard let url = Bundle.module.url(forResource: "stories", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { preconditionFailure("StarlightCore's stories.json is unreadable") }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(Stories.self, from: data)
        } catch {
            preconditionFailure("StarlightCore's stories.json is malformed: \(error)")
        }
    }()

    public subscript(constellation: String) -> Story? { stories[constellation] }
}

extension Catalogue {
    /// The constellations that can be drawn so far: bright figures of the northern mid-latitudes'
    /// evenings through the year, each with its story. The rest of the 88 come by season
    /// (painting-company row 131).
    public static let firstSet = ["Cas", "UMa", "Cyg", "Lyr", "Ori", "Leo", "Sco", "Gem",
                                  "Tau", "Peg", "And", "Per", "Boo", "Aql", "Aur", "CMa"]
}

extension Star {
    /// What to call it on the drawing: its proper name, else its Bayer letter or Flamsteed number,
    /// else its Bright Star number ("HR 1234").
    public var label: String {
        name ?? designation ?? "HR \(id)"
    }
}
