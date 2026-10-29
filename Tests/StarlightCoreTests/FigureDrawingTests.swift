import Foundation
import Testing
@testable import StarlightCore

/// Drawing Cassiopeia's W (542-403-264-168-21: Segin, Ruchbah, γ, Schedar, Caph) star to star.
struct FigureDrawingTests {
    let catalogue = Catalogue.bundled
    var drawing: FigureDrawing { FigureDrawing(constellation: catalogue.constellations["Cas"]!, catalogue: catalogue) }

    @Test func tappingAlongTheChain() {
        var d = drawing
        #expect(d.segments.count == 4)
        #expect(d.tap(21) == .selected(21))
        #expect(d.tap(21) == .deselected)
        #expect(d.tap(21) == .selected(21))
        #expect(d.tap(168) == .joined(.init(21, 168)))
        #expect(d.selected == 168)
        #expect(d.namedStars == [21, 168])
        #expect(d.tap(264) == .joined(.init(168, 264)))
        #expect(d.tap(403) == .joined(.init(264, 403)))
        #expect(d.tap(542) == .completed(.init(403, 542)))
        #expect(d.isComplete && d.hint == nil && d.selected == nil)
        #expect(d.lines.count == 4)
    }

    @Test func aLineThatDoesNotBelongIsForgotten() {
        var d = drawing
        _ = d.tap(21)
        #expect(d.tap(542) == .notJoined(21, 542))
        #expect(d.drawn.isEmpty && d.selected == 21)
        #expect(d.connect(168, 21) == .joined(.init(21, 168)))
        #expect(d.connect(21, 168) == .alreadyJoined(.init(21, 168)))
        #expect(d.selected == 168 && d.drawn.count == 1)
    }

    @Test func theHint() {
        var d = drawing
        // Nothing drawn, nothing selected: the brightest star a line touches (Schedar, 2.23).
        #expect(d.hint == 168)
        _ = d.tap(168)
        // From Schedar: the first undrawn line from it runs to γ.
        #expect(d.hint == 264)
        _ = d.tap(264)
        _ = d.tap(264)
        // Nothing selected again: continue from a star already drawn.
        #expect(d.hint == 168 || d.hint == 264)
        _ = d.tap(21)
        // Selected a star with no line left from it... Caph still has one (to Schedar).
        #expect(d.hint == 168)
    }

    @Test func resetAndComplete() {
        var d = drawing
        _ = d.tap(21)
        d.deselect()
        #expect(d.selected == nil)
        d.complete()
        #expect(d.isComplete && d.namedStars.count == 5)
        d.reset()
        #expect(d.drawn.isEmpty && d.selected == nil && d.remaining.count == 4)
    }
}
