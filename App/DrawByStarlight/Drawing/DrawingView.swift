import StarlightCore
import SwiftUI

/// Drawing one constellation, star to star, in tonight's sky: the one way to draw (painting-company
/// row 128). Only the sky and its names: a star glimmers where to begin; a line that belongs
/// stays and names its stars; one that doesn't fades; when you pause, the next star glimmers; the
/// whole figure comes alive, and its story is a tap away.
///
/// Demo scenarios: `draw-<name>` (fresh: `draw-cassiopeia`, `draw-ursa-major`), `draw-<name>-hint`
/// (two lines drawn, the next star glimmering), `draw-<name>-done` (whole), `draw-<name>-story`
/// (whole, the story up).
struct DrawingView: View {
    @State private var model: DrawingModel
    let sky: Sky
    let drawn: DrawnFigures
    @Environment(\.dismiss) private var dismiss
    /// The bottom of the window and of the sky's slot, in the window's coordinates: what the
    /// story's sheet would cover.
    @State private var windowBottom: CGFloat = 0
    @State private var skyBottom: CGFloat = 0

    init(constellation: Constellation, sky: Sky, drawn: DrawnFigures) {
        self.sky = sky
        self.drawn = drawn
        let scene = sky.scene(constellation)
        _model = State(initialValue: DrawingModel(
            scene: scene, story: sky.stories[constellation.id], catalogue: sky.catalogue,
            // Drawn before, and not since taken up again: whole; else the lines so far.
            alreadyDrawn: drawn.isDrawn(constellation.id) && drawn.lines(constellation.id).isEmpty,
            lines: drawn.lines(constellation.id)))
    }

    var body: some View {
        SkyCanvasView(model: model, showsBorder: model.isComplete)
            // The whole figure stays in view above its story.
            .padding(.bottom, model.showsStory ? storyInset : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY } action: { skyBottom = $0 }
            .padding(.vertical, 8)
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY + $0.safeAreaInsets.bottom } action: { windowBottom = $0 }
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle(Text(verbatim: model.name))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !model.isComplete {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            model.showMe()
                        } label: {
                            Label("Show me", systemImage: "sparkle")
                        }
                        .accessibilityHint("The next star glimmers.")
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            model.showsStory = true
                        } label: {
                            Label("Story", systemImage: "text.book.closed")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            model.drawAgain()
                        } label: {
                            Label("Draw again", systemImage: "arrow.counterclockwise")
                        }
                    }
                }
            }
            .sheet(isPresented: $model.showsStory) {
                FinishedFigureView(model: model, sky: sky, drawnAt: drawn.records[model.scene.constellation.id]?.first,
                                   firstDetent: Self.storyDetent) {
                    model.showsStory = false
                    dismiss()
                }
            }
            .onChange(of: model.isComplete) { _, complete in
                if complete { drawn.record(model.scene.constellation.id, at: sky.now) }
            }
            .onChange(of: model.lines) { _, lines in
                drawn.keep(lines, of: model.scene.constellation.id)
            }
            .onChange(of: model.announcement) { _, announcement in
                if let announcement { AccessibilityNotification.Announcement(announcement.text).post() }
            }
            .onAppear {
                model.appeared()
                #if DEBUG
                if let scenario = DemoMode.scenario {
                    model.demo(scenario)
                    // A story scenario is ready when its sheet is (`FinishedFigureView`).
                    if !scenario.contains("-story") { DemoMode.markReady() }
                }
                #endif
            }
            .onDisappear { model.disappeared() }
    }

    /// The story's sheet first rises this far, leaving the figure in view above it.
    private static let storyFraction: CGFloat = 0.5
    static let storyDetent = PresentationDetent.fraction(storyFraction)

    /// How much of the sky's slot the story's sheet covers, and a little air.
    private var storyInset: CGFloat {
        max(0, skyBottom - windowBottom * (1 - Self.storyFraction)) + 16
    }
}
