import Foundation
import Testing
@testable import DrawByStarlight

/// What you drew stays drawn: the records round-trip through their file and survive a bad one.
@MainActor
struct DrawnFiguresTests {
    func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "drawn-\(UUID().uuidString).json")
    }

    @Test func recordsAndReads() throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file) }
        let first = DrawnFigures(file: file)
        #expect(!first.isDrawn("Cas"))
        let night = Date(timeIntervalSince1970: 1_792_976_400)
        first.record("Cas", at: night)
        first.record("Cas", at: night.addingTimeInterval(86_400))
        #expect(first.isDrawn("Cas"))

        let second = DrawnFigures(file: file)
        let record = try #require(second.records["Cas"])
        #expect(abs(record.first.timeIntervalSince(night)) < 1)
        #expect(abs(record.latest.timeIntervalSince(night) - 86_400) < 1)
        #expect(!second.isDrawn("Ori"))
    }

    @Test func aBadFileStartsOver() throws {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file) }
        try Data("not json".utf8).write(to: file)
        let figures = DrawnFigures(file: file)
        #expect(figures.records.isEmpty)
        figures.record("Lyr")
        #expect(DrawnFigures(file: file).isDrawn("Lyr"))
    }

    @Test func inMemoryOnly() {
        let figures = DrawnFigures(file: nil)
        figures.record("Cyg")
        #expect(figures.isDrawn("Cyg"))
    }

    @Test func linesInProgressAreKept() {
        let file = temporaryFile()
        defer { try? FileManager.default.removeItem(at: file) }
        let figures = DrawnFigures(file: file)
        figures.keep([[21, 168]], of: "Cas")
        #expect(!figures.isDrawn("Cas"))
        #expect(DrawnFigures(file: file).lines("Cas") == [[21, 168]])
        figures.record("Cas")
        #expect(DrawnFigures(file: file).isDrawn("Cas") && DrawnFigures(file: file).lines("Cas") == [[21, 168]])
        figures.keep([], of: "Cas")
        #expect(DrawnFigures(file: file).lines("Cas").isEmpty && DrawnFigures(file: file).isDrawn("Cas"))
    }
}
