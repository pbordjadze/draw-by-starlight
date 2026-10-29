import CoreGraphics
import Foundation
import StarlightCore
import Testing
@testable import DrawByStarlight

/// The drawing screen's state: taps and drags draw Cassiopeia's W, a pause brings the glimmer,
/// the last line brings the sparkles and then the story.
@MainActor
struct DrawingModelTests {
    let sky = Sky(place: Place(latitude: 40, longitude: -75), now: Date(timeIntervalSince1970: 1_792_976_400),
                  timeZone: TimeZone(identifier: "America/New_York")!)

    func model(pause: Duration = .seconds(60), drawn: Bool = false) -> DrawingModel {
        let constellation = sky.constellation("Cas")!
        return DrawingModel(scene: sky.scene(constellation), story: sky.stories["Cas"], catalogue: sky.catalogue,
                            alreadyDrawn: drawn, pause: pause)
    }

    @Test func tapsDrawTheW() {
        let m = model()
        #expect(m.prompt == .start)
        m.tap(21)
        #expect(m.prompt == .next && m.drawing.selected == 21)
        m.tap(542)
        #expect(m.prompt == .forgotten && m.forgotten == DrawingModel.Line(from: 21, to: 542))
        m.tap(168)
        #expect(m.drawing.lines.count == 1 && m.lastJoined == 168 && m.prompt == .none)
        #expect(m.announcement?.text == "Caph to Schedar: a line of the figure.")
        m.tap(264)
        m.tap(403)
        #expect(!m.isComplete)
        m.tap(542)
        #expect(m.isComplete && m.sparkles && m.lastJoined == 542 && !m.showsStory)
        #expect(m.announcement?.text == "Cassiopeia is whole.")
    }

    @Test func aDragJoinsTwoStars() {
        let m = model()
        let a = CGPoint(x: 100, y: 100), b = CGPoint(x: 160, y: 140)
        m.touchBegan(on: 168, at: a)
        m.touchMoved(to: CGPoint(x: 103, y: 101), over: 168)
        #expect(m.drag?.moved == false && m.drag?.target == nil)
        m.touchMoved(to: b, over: 264)
        #expect(m.drag?.moved == true && m.drag?.target == 264 && m.prompt == .dragging)
        m.touchEnded(on: 264)
        #expect(m.drawing.lines == [FigureDrawing.Segment(168, 264)] && m.drag == nil && m.lastJoined == 264)
        // A touch that starts on no star draws nothing; a drag let go on the sky keeps the selection.
        m.touchBegan(on: nil, at: a)
        m.touchEnded(on: 403)
        #expect(m.drawing.lines.count == 1)
        m.touchBegan(on: 264, at: a)
        m.touchMoved(to: b, over: nil)
        m.touchEnded(on: nil)
        #expect(m.drawing.selected == 264 && m.drawing.lines.count == 1)
        // A tap on the selected star lets go of it.
        m.touchBegan(on: 264, at: a)
        m.touchEnded(on: 264)
        #expect(m.drawing.selected == nil)
    }

    @Test func aPauseBringsTheGlimmer() async throws {
        let m = model(pause: .milliseconds(40))
        m.appeared()
        #expect(m.hint == nil)
        try await Task.sleep(for: .milliseconds(400))
        // Nothing drawn, nothing selected: Schedar, the brightest.
        #expect(m.hint == 168)
        m.tap(168)
        // The glimmer moves on to the next star at once.
        #expect(m.hint == 264)
        m.tap(264)
        #expect(m.hint == nil)
        m.disappeared()
    }

    @Test func showMeAndDrawAgain() {
        let m = model()
        m.showMe()
        #expect(m.hint == 168)
        m.tap(168)
        m.tap(264)
        #expect(m.hint == nil && m.drawing.lines.count == 1)
        m.drawAgain()
        #expect(m.drawing.lines.isEmpty && m.prompt == .start && m.hint == nil)
        m.disappeared()
    }

    @Test func theStoryFollowsTheSparkles() async throws {
        let m = model()
        for star in [542, 403, 264, 168, 21] { m.tap(star) }
        #expect(m.isComplete && m.sparkles)
        try await Task.sleep(for: .seconds(2))
        #expect(!m.sparkles && m.showsStory)
        #expect(m.story?.title == "Cassiopeia (constellation)")
    }

    @Test func linesDrawnBeforeComeBack() {
        let constellation = sky.constellation("Cas")!
        let m = DrawingModel(scene: sky.scene(constellation), story: nil, catalogue: sky.catalogue, alreadyDrawn: false,
                             lines: [[21, 168], [168, 264], [7, 8]])
        #expect(m.lines == [[21, 168], [168, 264]] && m.drawing.selected == nil && m.prompt == .none && !m.isComplete)
        m.tap(264)
        m.tap(403)
        #expect(m.lines.count == 3)
    }

    @Test func alreadyDrawnOpensWhole() {
        let m = model(drawn: true)
        #expect(m.isComplete && m.drawing.namedStars.count == 5 && m.prompt == .none)
        m.tap(21)
        #expect(m.drawing.selected == nil)
    }
}
