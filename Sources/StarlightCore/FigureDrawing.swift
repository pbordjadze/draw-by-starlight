import Foundation

/// A figure being drawn star to star: which of its lines are drawn, which star the next line
/// starts from, and which line to show when the stargazer hesitates. The one way to draw: a line
/// that belongs stays, one that doesn't is forgotten, and help comes only when asked for or
/// paused for.
public struct FigureDrawing: Sendable, Equatable {
    /// One line of the figure, between two stars by Bright Star number, the smaller first.
    public struct Segment: Sendable, Hashable {
        public let a: Int
        public let b: Int

        public init(_ x: Int, _ y: Int) {
            a = min(x, y)
            b = max(x, y)
        }

        public func touches(_ star: Int) -> Bool { star == a || star == b }

        /// The other end.
        public func other(than star: Int) -> Int { star == a ? b : a }
    }

    /// What a touch did.
    public enum Outcome: Sendable, Equatable {
        /// A first star, waiting for the second.
        case selected(Int)
        /// The selected star tapped again.
        case deselected
        /// A line that belongs: drawn, and the next line starts from its far end.
        case joined(Segment)
        /// A line already drawn: nothing new, the next line starts from its far end.
        case alreadyJoined(Segment)
        /// Two stars the figure doesn't join: forgotten.
        case notJoined(Int, Int)
        /// The last line: the figure is whole.
        case completed(Segment)
    }

    /// The figure's lines, in the order its chains run.
    public let segments: [Segment]
    public let magnitudes: [Int: Double]
    public private(set) var drawn: Set<Segment> = []
    /// The star the next line starts from, if one is chosen.
    public private(set) var selected: Int?

    public init(constellation: Constellation, catalogue: Catalogue) {
        segments = constellation.segments.map { Segment($0.0, $0.1) }
        magnitudes = Dictionary(uniqueKeysWithValues: constellation.stars.map { ($0, catalogue.stars[$0]?.magnitude ?? 6) })
    }

    public var isComplete: Bool { drawn.count == segments.count }

    /// The lines still to draw, in the figure's order.
    public var remaining: [Segment] { segments.filter { !drawn.contains($0) } }

    /// The stars a drawn line touches: the ones whose names show.
    public var namedStars: Set<Int> { Set(drawn.flatMap { [$0.a, $0.b] }) }

    public var lines: [Segment] { segments.filter { drawn.contains($0) } }

    /// A tap on a star: the first of a line, or the second.
    public mutating func tap(_ star: Int) -> Outcome {
        guard let from = selected else {
            selected = star
            return .selected(star)
        }
        if from == star {
            selected = nil
            return .deselected
        }
        return connect(from, star)
    }

    /// A line dragged from one star to another.
    public mutating func connect(_ from: Int, _ to: Int) -> Outcome {
        let segment = Segment(from, to)
        guard segments.contains(segment) else {
            selected = from
            return .notJoined(from, to)
        }
        selected = to
        if drawn.contains(segment) { return .alreadyJoined(segment) }
        drawn.insert(segment)
        guard isComplete else { return .joined(segment) }
        selected = nil
        return .completed(segment)
    }

    /// Lets go of the selected star.
    public mutating func deselect() {
        selected = nil
    }

    /// Starts over, keeping nothing.
    public mutating func reset() {
        drawn = []
        selected = nil
    }

    /// Shows the figure whole, as when it was drawn before.
    public mutating func complete() {
        drawn = Set(segments)
        selected = nil
    }

    /// The star to show when the stargazer hesitates: the far end of a line from the selected
    /// star; with nothing selected, where to begin: a star already in the drawing that a missing
    /// line leaves from, else the brightest star a missing line touches. Nil when the figure is
    /// whole.
    public var hint: Int? {
        let remaining = remaining
        guard let first = remaining.first else { return nil }
        if let selected {
            if let next = remaining.first(where: { $0.touches(selected) }) { return next.other(than: selected) }
        }
        let named = namedStars
        if let next = remaining.first(where: { named.contains($0.a) || named.contains($0.b) }) {
            return named.contains(next.a) ? next.a : next.b
        }
        let brightness = { (star: Int) in self.magnitudes[star] ?? 6 }
        let candidates = remaining.flatMap { [$0.a, $0.b] }
        return candidates.min { brightness($0) < brightness($1) } ?? first.a
    }
}
