import CoreGraphics
import Foundation
import Observation
import StarlightCore

/// The drawing screen's state: the figure laid out in tonight's sky, the lines drawn so far, what
/// the finger is doing, and the glimmer that comes only when the stargazer pauses.
@Observable
final class DrawingModel {
    /// A line between two of the figure's stars.
    nonisolated struct Line: Equatable {
        let from: Int
        let to: Int
    }

    /// A finger down on a star.
    nonisolated struct Drag: Equatable {
        let from: Int
        let start: CGPoint
        var at: CGPoint
        /// Moved far enough to be a drag, not a tap.
        var moved = false
        /// The star the line would reach if the finger lifted now.
        var target: Int?
    }

    /// The one line of help under the sky.
    nonisolated enum Prompt: Equatable {
        case start, next, forgotten, dragging, none
    }

    let scene: FigureScene
    let story: Story?
    let figure: [FigureScene.PlacedStar]
    private(set) var drawing: FigureDrawing
    /// The star glimmering, when the stargazer has paused or asked.
    private(set) var hint: Int?
    /// A line that didn't belong, fading away.
    private(set) var forgotten: Line?
    /// The line following the finger.
    private(set) var drag: Drag?
    /// The star the last line reached: where the sparkles appear.
    private(set) var lastJoined: Int?
    private(set) var isComplete: Bool
    /// The two gold sparkles of the fill moment, for a breath after the last line.
    private(set) var sparkles = false
    private(set) var prompt: Prompt
    var showsStory = false

    /// How long a pause brings the glimmer.
    let pause: Duration
    private var pauseTask: Task<Void, Never>?
    private var forgetTask: Task<Void, Never>?
    private var finishTask: Task<Void, Never>?

    /// `lines`: the lines drawn before, to pick up from (ignored when `alreadyDrawn`).
    init(scene: FigureScene, story: Story?, catalogue: Catalogue, alreadyDrawn: Bool, lines: [[Int]] = [],
         pause: Duration = .seconds(4)) {
        self.scene = scene
        self.story = story
        figure = scene.figure
        self.pause = pause
        var drawing = FigureDrawing(constellation: scene.constellation, catalogue: catalogue)
        if alreadyDrawn {
            drawing.complete()
        } else {
            for line in lines where line.count == 2 { _ = drawing.connect(line[0], line[1]) }
            drawing.deselect()
        }
        self.drawing = drawing
        let complete = alreadyDrawn || drawing.isComplete
        isComplete = complete
        prompt = complete || !drawing.drawn.isEmpty ? .none : .start
    }

    /// The lines drawn so far, as pairs of Bright Star numbers, for keeping.
    var lines: [[Int]] { drawing.lines.map { [$0.a, $0.b] } }

    var name: String { scene.constellation.name }

    func label(_ star: Int) -> String {
        figure.first { $0.id == star }?.star.label ?? ""
    }

    /// The screen is up: the pause starts.
    func appeared() {
        if !isComplete { wait() }
    }

    func disappeared() {
        pauseTask?.cancel()
        forgetTask?.cancel()
        finishTask?.cancel()
    }

    // MARK: Touches

    /// A finger down, on a star or not.
    func touchBegan(on star: Int?, at location: CGPoint) {
        guard !isComplete, drag == nil, let star else { return }
        drag = Drag(from: star, start: location, at: location)
        wait()
    }

    /// `target`: the star under the finger now, if one.
    func touchMoved(to location: CGPoint, over target: Int?) {
        guard var current = drag else { return }
        current.at = location
        current.target = target == current.from ? nil : target
        if !current.moved, hypot(location.x - current.start.x, location.y - current.start.y) > 8 {
            current.moved = true
            prompt = .dragging
        }
        drag = current
    }

    /// The finger lifted, on a star or not: a tap on the star it started from, or a line to the
    /// star it ended on.
    func touchEnded(on star: Int?) {
        guard let current = drag else { return }
        drag = nil
        if !current.moved || star == current.from {
            let from = drawing.selected
            handle(drawing.tap(current.from), from: from)
        } else if let star {
            handle(drawing.connect(current.from, star), from: current.from)
        } else {
            prompt = drawing.drawn.isEmpty ? (drawing.selected == nil ? .start : .next) : .none
            wait()
        }
    }

    /// A tap by VoiceOver or a test.
    func tap(_ star: Int) {
        guard !isComplete else { return }
        let from = drawing.selected
        handle(drawing.tap(star), from: from)
    }

    /// "Show me": the next star glimmers now.
    func showMe() {
        guard !isComplete else { return }
        pauseTask?.cancel()
        hint = drawing.hint
    }

    /// Starts over: the lines go, the figure stays where it is.
    func drawAgain() {
        finishTask?.cancel()
        drawing.reset()
        hint = nil
        forgotten = nil
        lastJoined = nil
        sparkles = false
        isComplete = false
        showsStory = false
        prompt = .start
        wait()
    }

    /// What VoiceOver says of the last touch; numbered so the same words twice still speak.
    nonisolated struct Announcement: Equatable {
        let text: String
        let count: Int
    }

    private(set) var announcement: Announcement?

    private func announce(_ text: String) {
        announcement = Announcement(text: text, count: (announcement?.count ?? 0) + 1)
    }

    /// `from`: the star the line was drawn from, when one was.
    private func handle(_ outcome: FigureDrawing.Outcome, from: Int?) {
        switch outcome {
        case .selected(let star):
            prompt = drawing.drawn.isEmpty ? .next : .none
            // Help asked for and taken: keep helping until a line is drawn.
            if hint == star { hint = drawing.hint }
            announce(String(localized: "voiceover.selected", defaultValue: "\(label(star)) selected. Now choose the next star.",
                                  comment: "VoiceOver, after a star is chosen as a line's start; the argument is the star's name."))
            wait()
        case .deselected:
            prompt = drawing.drawn.isEmpty ? .start : .none
            announce(String(localized: "Nothing selected."))
            wait()
        case .joined(let segment):
            hint = nil
            lastJoined = segment.other(than: from ?? segment.a)
            prompt = .none
            announce(String(localized: "voiceover.joined", defaultValue: "\(label(segment.a)) to \(label(segment.b)): a line of the figure.",
                                  comment: "VoiceOver, after a line that belongs is drawn; the arguments are its two stars' names."))
            wait()
        case .alreadyJoined:
            prompt = .none
            announce(String(localized: "Already drawn."))
            wait()
        case .notJoined(let from, let to):
            forget(Line(from: from, to: to))
            prompt = .forgotten
            announce(String(localized: "Those two aren't joined."))
            wait()
        case .completed(let segment):
            hint = nil
            lastJoined = segment.other(than: from ?? segment.a)
            isComplete = true
            prompt = .none
            pauseTask?.cancel()
            sparkles = true
            announce(String(localized: "voiceover.whole", defaultValue: "\(name) is whole.",
                                  comment: "VoiceOver, when the last line of a figure is drawn; the argument is the constellation's name."))
            finishTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(1.4))
                guard !Task.isCancelled, let self else { return }
                sparkles = false
                showsStory = true
            }
        }
    }

    private func forget(_ line: Line) {
        forgetTask?.cancel()
        forgotten = line
        forgetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.15))
            guard !Task.isCancelled, let self else { return }
            forgotten = nil
        }
    }

    /// The pause: after it, with no new line, the next star glimmers.
    private func wait() {
        pauseTask?.cancel()
        guard !isComplete else { return }
        pauseTask = Task { [weak self] in
            try? await Task.sleep(for: self?.pause ?? .seconds(4))
            guard !Task.isCancelled, let self, !isComplete, drag == nil else { return }
            hint = drawing.hint
        }
    }

    #if DEBUG
    /// Demo scenarios: two lines drawn and the next star glimmering, or the figure whole with its
    /// story up.
    func demo(_ scenario: String) {
        if scenario.contains("-hint") {
            let stars = scene.constellation.stars
            _ = drawing.tap(stars[0])
            _ = drawing.tap(stars[1])
            _ = drawing.tap(stars[2])
            prompt = .none
            pauseTask?.cancel()
            hint = drawing.hint
        } else if scenario.contains("-done") {
            pauseTask?.cancel()
            drawing.complete()
            isComplete = true
            prompt = .none
            showsStory = true
        }
    }
    #endif
}
