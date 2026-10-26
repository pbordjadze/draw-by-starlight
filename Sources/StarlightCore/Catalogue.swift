import Foundation

/// A star of the Yale Bright Star Catalogue, 5th revised edition (Hoffleit and Warren, 1991).
public struct Star: Sendable, Hashable, Identifiable {
    /// Its Harvard Revised (Bright Star) number.
    public let id: Int
    /// Its place at the equator, equinox and epoch J2000.0.
    public let j2000: Equatorial
    /// Its proper motion in right ascension (projected on the sky, cos δ · dα/dt) and in
    /// declination, in arcseconds a year.
    public let properMotion: (rightAscension: Double, declination: Double)
    /// Its visual magnitude: smaller is brighter.
    public let magnitude: Double
    /// Its B−V color index, when measured: below 0 blue-white, above 1 orange-red.
    public let colorIndex: Double?
    /// Its Bayer letter ("α", "θ1") or else Flamsteed number ("58"), when it has one.
    public let designation: String?
    /// The IAU abbreviation of the constellation its designation belongs to ("Ori").
    public let constellation: String?
    /// Its proper name, as the IAU's Working Group on Star Names lists it ("Betelgeuse").
    public let name: String?

    /// Its place for the mean equator and equinox of `moment`: moved by its proper motion, then
    /// precessed from J2000.0.
    public func position(at moment: JulianDay) -> Equatorial {
        let years = (moment.value - JulianDay.j2000.value) / 365.25
        let declination = j2000.declination + properMotion.declination * years / 3600
        let rightAscension = j2000.rightAscension
            + properMotion.rightAscension * years / 3600 / max(cos(degrees: j2000.declination), 1e-9)
        return Equatorial(rightAscension: rightAscension, declination: declination)
            .precessed(from: .j2000, to: moment)
    }

    public static func == (a: Star, b: Star) -> Bool { a.id == b.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// One of the IAU's 88 constellations: its figure's lines and its official border.
public struct Constellation: Sendable, Identifiable {
    /// Its IAU abbreviation ("UMa").
    public let id: String
    /// Its Latin name ("Ursa Major").
    public let name: String
    /// Its figure: each line a chain of stars, by Bright Star number, drawn star to star.
    public let lines: [[Int]]
    /// Its border as the IAU drew it (Delporte, 1930), at the equator and equinox of J2000.0: one
    /// closed outline (two for Serpens), with points close enough to join with straight lines.
    public let border: [[Equatorial]]

    /// The figure's stars, by Bright Star number, each once, in the order the lines first reach them.
    public var stars: [Int] {
        var seen = Set<Int>()
        return lines.flatMap { $0 }.filter { seen.insert($0).inserted }
    }

    /// The figure's segments, each a pair of Bright Star numbers, each once.
    public var segments: [(Int, Int)] {
        var seen = Set<[Int]>()
        return lines.flatMap { line in zip(line, line.dropFirst()).map { ($0, $1) } }
            .filter { seen.insert([min($0.0, $0.1), max($0.0, $0.1)]).inserted }
    }
}

/// The sky StarlightCore bundles: every star of the Bright Star Catalogue (to about magnitude
/// 6.5), the IAU's star names, and the 88 constellations' figures and borders. Its sources and
/// licenses are in `Resources/CREDITS.md`.
public struct Catalogue: Sendable {
    /// Every star, by Bright Star number.
    public let stars: [Int: Star]
    /// The 88 constellations, by IAU abbreviation.
    public let constellations: [String: Constellation]

    /// The catalogue the package bundles.
    public static let bundled: Catalogue = {
        do {
            return try Catalogue(resources: .module)
        } catch {
            preconditionFailure("StarlightCore's bundled catalogue is unreadable: \(error)")
        }
    }()

    enum ReadError: Error {
        case missing(String)
        case malformed(file: String, line: String)
    }

    init(resources bundle: Bundle) throws {
        func rows(_ name: String) throws -> [[Substring]] {
            guard let url = bundle.url(forResource: name, withExtension: "tsv") else { throw ReadError.missing(name) }
            return try String(contentsOf: url, encoding: .utf8)
                .split(separator: "\n")
                .filter { !$0.hasPrefix("#") }
                .map { $0.split(separator: "\t", omittingEmptySubsequences: false) }
        }

        var names: [Int: String] = [:]
        for row in try rows("names") {
            guard row.count == 2, let number = Int(row[0]) else { throw ReadError.malformed(file: "names", line: row.joined(separator: "\t")) }
            names[number] = String(row[1])
        }

        var stars: [Int: Star] = [:]
        for row in try rows("stars") {
            guard row.count == 9, let number = Int(row[0]), let ra = Double(row[1]), let dec = Double(row[2]),
                  let pmRA = Double(row[3]), let pmDec = Double(row[4]), let magnitude = Double(row[5])
            else { throw ReadError.malformed(file: "stars", line: row.joined(separator: "\t")) }
            stars[number] = Star(
                id: number,
                j2000: Equatorial(rightAscension: ra, declination: dec),
                properMotion: (pmRA, pmDec),
                magnitude: magnitude,
                colorIndex: Double(row[6]),
                designation: row[7].isEmpty ? nil : String(row[7]),
                constellation: row[8].isEmpty ? nil : String(row[8]),
                name: names[number])
        }

        var borders: [String: [[Equatorial]]] = [:]
        for row in try rows("borders") {
            let corners = row.count == 2 ? row[1].split(separator: " ").compactMap { pair -> Equatorial? in
                let parts = pair.split(separator: ",")
                guard parts.count == 2, let ra = Double(parts[0]), let dec = Double(parts[1]) else { return nil }
                return Equatorial(rightAscension: ra, declination: dec)
            } : []
            guard row.count == 2, corners.count >= 3 else { throw ReadError.malformed(file: "borders", line: row.joined(separator: "\t")) }
            // "SER1" and "SER2" are Serpens's head and tail.
            let id = String(row[0].prefix(3)).uppercased()
            borders[id, default: []].append(Self.outline(b1875: corners))
        }

        var constellations: [String: Constellation] = [:]
        for row in try rows("figures") {
            let lines = row.count == 3 ? row[2].split(separator: " ").map { $0.split(separator: "-").compactMap { Int($0) } } : []
            guard row.count == 3, !lines.isEmpty, lines.allSatisfy({ $0.count >= 2 && $0.allSatisfy { stars[$0] != nil } }),
                  let border = borders[row[0].uppercased()]
            else { throw ReadError.malformed(file: "figures", line: row.joined(separator: "\t")) }
            constellations[String(row[0])] = Constellation(id: String(row[0]), name: String(row[1]), lines: lines, border: border)
        }

        self.stars = stars
        self.constellations = constellations
    }

    /// The Besselian epoch B1875.0, the equinox of Delporte's borders.
    static let b1875 = JulianDay(2_405_889.258_550_475)

    /// A border given by its corners at B1875: its edges run along that equinox's parallels and
    /// meridians, so the parallels are filled in at least every degree before precessing to J2000,
    /// where they are no longer parallels.
    static func outline(b1875 corners: [Equatorial]) -> [Equatorial] {
        var points: [Equatorial] = []
        for (index, corner) in corners.enumerated() {
            let next = corners[(index + 1) % corners.count]
            points.append(corner)
            let span = (next.rightAscension - corner.rightAscension).signedDegrees
            guard abs(corner.declination) < 90, corner.declination == next.declination, abs(span) > 1 else { continue }
            let steps = Int(abs(span).rounded(.up))
            for step in 1..<steps {
                points.append(Equatorial(
                    rightAscension: corner.rightAscension + span * Double(step) / Double(steps),
                    declination: corner.declination))
            }
        }
        return points.map { $0.precessed(from: b1875, to: .j2000) }
    }
}
