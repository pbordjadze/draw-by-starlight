import Foundation
import Observation
import os
import StarlightCore

/// What you drew stays drawn: each constellation's lines so far, and when its figure was first and
/// last whole, in a small JSON file in the app's Application Support folder (on the device only,
/// like everything).
@Observable
final class DrawnFigures {
    nonisolated struct Record: Codable, Equatable {
        /// The first time its figure was whole; nil while it is still being drawn.
        var first: Date?
        /// The latest.
        var latest: Date?
        /// The lines drawn so far, each a pair of Bright Star numbers.
        var lines: [[Int]] = []
    }

    private(set) var records: [String: Record]
    private let file: URL?

    /// `file` nil keeps the records in memory only.
    init(file: URL?) {
        self.file = file
        records = Self.read(file)
    }

    static let shared = DrawnFigures(file: defaultFile)

    static var defaultFile: URL? {
        try? FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appending(path: "drawn.json")
    }

    /// Whole at least once.
    func isDrawn(_ constellation: String) -> Bool { records[constellation]?.first != nil }

    /// The lines drawn so far, to pick up where the stargazer left off.
    func lines(_ constellation: String) -> [[Int]] { records[constellation]?.lines ?? [] }

    /// The lines to ink in for a figure, each a pair of Bright Star numbers, the smaller first: the
    /// lines drawn so far, or all of them once it is whole and not taken up again (as the drawing
    /// opens it).
    func inked(_ constellation: Constellation) -> Set<[Int]> {
        let lines = lines(constellation.id)
        let pairs = lines.isEmpty && isDrawn(constellation.id)
            ? constellation.segments.map { [$0.0, $0.1] }
            : lines.filter { $0.count == 2 }
        return Set(pairs.map { [min($0[0], $0[1]), max($0[0], $0[1])] })
    }

    /// The figure is whole.
    func record(_ constellation: String, at date: Date = .now) {
        var record = records[constellation] ?? Record()
        record.first = record.first ?? date
        record.latest = date
        records[constellation] = record
        save()
    }

    /// The lines drawn so far (empty: started over).
    func keep(_ lines: [[Int]], of constellation: String) {
        var record = records[constellation] ?? Record()
        record.lines = lines
        records[constellation] = record
        save()
    }

    private static func read(_ file: URL?) -> [String: Record] {
        guard let file, let data = try? Data(contentsOf: file) else { return [:] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode([String: Record].self, from: data)
        } catch {
            Log.sky.error("drawn.json unreadable, starting over: \(error, privacy: .public)")
            return [:]
        }
    }

    private func save() {
        guard let file else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        do {
            try encoder.encode(records).write(to: file, options: .atomic)
        } catch {
            Log.sky.error("drawn.json not saved: \(error, privacy: .public)")
        }
    }
}
