import StarlightCore
import SwiftUI

/// Drawing one constellation, star to star, in tonight's sky: the one way to draw (painting-company
/// row 128). A line that belongs stays and names its stars; one that doesn't fades; when you
/// pause, the next star glimmers; when the figure is whole, its story.
///
/// Demo scenarios: `draw-<name>` (fresh: `draw-cassiopeia`, `draw-ursa-major`), `draw-<name>-hint`
/// (two lines drawn, the next star glimmering), `draw-<name>-done` (whole, the story up).
struct DrawingView: View {
    @State private var model: DrawingModel
    let sky: Sky
    let drawn: DrawnFigures
    @Environment(\.dismiss) private var dismiss

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
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: SkyWords.standing(model.scene, place: sky.place, time: sky.time))
                .font(.subheadline)
                .foregroundStyle(Theme.lavender)
                .padding(.horizontal, 20)
                .padding(.top, 4)
            SkyCanvasView(model: model, showsBorder: model.isComplete)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 8)
            footer
        }
        .background(Theme.paper.ignoresSafeArea())
        .navigationTitle(Text(verbatim: model.name))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if model.isComplete {
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
            FinishedFigureView(model: model, sky: sky, drawnAt: drawn.records[model.scene.constellation.id]?.first) {
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
                if !model.showsStory { DemoMode.markReady() }
            }
            #endif
        }
        .onDisappear { model.disappeared() }
    }

    /// The one line of help, "Show me", and the hint about pausing until the first line is drawn.
    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                promptText
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.updatesFrequently)
                if !model.isComplete {
                    Button("Show me") { model.showMe() }
                        .font(.body.weight(.semibold))
                        .accessibilityHint("The next star glimmers.")
                }
            }
            .frame(minHeight: 44)
            if model.drawing.drawn.isEmpty && !model.isComplete {
                Text("Pause, and the next star glimmers.")
                    .font(.footnote)
                    .foregroundStyle(Theme.lavender)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var promptText: some View {
        switch model.prompt {
        case .start: Text("Join the stars, one line at a time.")
        case .next: Text("Now to the next star.")
        case .forgotten: Text("Those two aren't joined.")
        case .dragging: Text("Let go on a star.")
        case .none: Text(verbatim: "")
        }
    }
}
