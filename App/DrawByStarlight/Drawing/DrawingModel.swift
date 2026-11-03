import CoreGraphics
import Foundation
import Observation
import StarlightCore

/// The drawing screen's state: the figure laid out in tonight's sky, the lines drawn so far, what
/// the finger is doing, and the glimmer that comes only when the stargazer pauses. No words on
/// screen: what happens in the sky says it (VoiceOver hears it).
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
    /// When the last line was drawn, while the figure is coming alive: its lines light up one by
    /// one and its border fades in. Nil otherwise.
    private(set) var cameAlive: Date?
    /// The story, on demand.
    var showsStory = false

    /// How long a pause brings the glimmer.
    let pause: Duration
    /// The pause on a first look, before anything is touched: shorter, so the sky shows where to
    /// begin instead of saying it.
    let firstPause: Duration
    /// How long the figure takes to come alive.
    static let aliveDuration: Double = 3
    private var pauseTask: Task<Void, Never>?
    private var forgetTask: Task<Void, Never>?
    private var finishTask: Task<Void, Never>?

    /// `lines`: the lines drawn before, to pick up from (ignored when `alreadyDrawn`).
    init(scene: FigureScene, story: Story?, catalogue: Catalogue, alreadyDrawn: Bool, lines: [[Int]] = [],
         pause: Duration = .seconds(4), firstPause: Duration = .seconds(1.5)) {
        self.scene = scene
        self.story = story
        figure = scene.figure
        self.pause = pause
        self.firstPause = min(pause, firstPause)
        var drawing = FigureDrawing(constellation: scene.constellation, catalogue: catalogue)
        if alreadyDrawn {
            drawing.complete()
        } else {
            for line in lines where line.count == 2 { _ = drawing.connect(line[0], line[1]) }
            drawing.deselect()
        }
        self.drawing = drawing
        isComplete = alreadyDrawn || drawing.isComplete
    }

    /// The lines drawn so far, as pairs of Bright Star numbers, for keeping.
    var lines: [[Int]] { drawing.lines.map { [$0.a, $0.b] } }

    var name: String { scene.constellation.name }

    /// Gold: a line has reached it, or the figure is whole. Until then it is white.
    func isLit(_ star: Int) -> Bool { isComplete || drawing.namedStars.contains(star) }

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
        glimmer(drawing.hint)
    }

    /// A star glimmers, and VoiceOver says which.
    private func glimmer(_ star: Int?) {
        hint = star
        if let star {
            announce(String(localized: "voiceover.glimmer", defaultValue: "\(label(star)) glimmers.",
                            comment: "VoiceOver, when a star glimmers to show the next line; the argument is the star's name."))
        }
    }

    /// Starts over: the lines go, the figure stays where it is.
    func drawAgain() {
        finishTask?.cancel()
        drawing.reset()
        hint = nil
        forgotten = nil
        lastJoined = nil
        sparkles = false
        cameAlive = nil
        isComplete = false
        showsStory = false
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
            // Help on screen: it follows the selection until a line is drawn.
            if hint != nil { glimmer(drawing.hint) }
            announce(String(localized: "voiceover.selected", defaultValue: "\(label(star)) selected. Now choose the next star.",
                                  comment: "VoiceOver, after a star is chosen as a line's start; the argument is the star's name."))
            wait()
        case .deselected:
            announce(String(localized: "Nothing selected."))
            wait()
        case .joined(let segment):
            hint = nil
            lastJoined = segment.other(than: from ?? segment.a)
            announce(String(localized: "voiceover.joined", defaultValue: "\(label(segment.a)) to \(label(segment.b)): a line of the figure.",
                                  comment: "VoiceOver, after a line that belongs is drawn; the arguments are its two stars' names."))
            wait()
        case .alreadyJoined:
            announce(String(localized: "Already drawn."))
            wait()
        case .notJoined(let from, let to):
            forget(Line(from: from, to: to))
            announce(String(localized: "Those two aren't joined."))
            wait()
        case .completed(let segment):
            hint = nil
            lastJoined = segment.other(than: from ?? segment.a)
            isComplete = true
            pauseTask?.cancel()
            sparkles = true
            cameAlive = Date.now
            announce(String(localized: "voiceover.whole", defaultValue: "\(name) is whole.",
                                  comment: "VoiceOver, when the last line of a figure is drawn; the argument is the constellation's name."))
            // The figure comes alive and stays; its story waits to be asked for.
            finishTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(1.4))
                guard !Task.isCancelled, let self else { return }
                sparkles = false
                try? await Task.sleep(for: .seconds(DrawingModel.aliveDuration - 1.4))
                guard !Task.isCancelled else { return }
                cameAlive = nil
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
        let firstLook = drawing.drawn.isEmpty && drawing.selected == nil && hint == nil
        let delay = firstLook ? firstPause : pause
        pauseTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self, !isComplete, drag == nil else { return }
            glimmer(drawing.hint)
        }
    }

    #if DEBUG
    /// Demo scenarios: two lines drawn and the next star glimmering, the figure whole, or the
    /// figure whole with its story up.
    func demo(_ scenario: String) {
        if scenario.contains("-hint") {
            let stars = scene.constellation.stars
            _ = drawing.tap(stars[0])
            _ = drawing.tap(stars[1])
            _ = drawing.tap(stars[2])
            pauseTask?.cancel()
            glimmer(drawing.hint)
        } else if scenario.contains("-done") || scenario.contains("-story") {
            pauseTask?.cancel()
            drawing.complete()
            isComplete = true
            guard scenario.contains("-story") else { return }
            // A beat after the push: a sheet presented in the same instant as a navigation push
            // can leave the screen blank.
            finishTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(0.6))
                guard !Task.isCancelled, let self else { return }
                showsStory = true
            }
        }
    }
    #endif
}
