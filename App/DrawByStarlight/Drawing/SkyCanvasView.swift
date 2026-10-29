import Foundation
import StarlightCore
import SwiftUI

/// The sky of the drawing: the faint stars around the figure, the figure's stars in gold, the
/// lines drawn, the line following the finger, a line that didn't belong fading in lavender, the
/// glimmer, and the names of the stars a line has reached. One gesture draws; VoiceOver gets a
/// button per star.
struct SkyCanvasView: View {
    let model: DrawingModel
    /// The IAU border, shown once the figure is whole.
    var showsBorder = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let layout = FigureLayout(size: geometry.size, figure: model.figure.map(\.point))
            ZStack {
                backdrop(layout)
                TimelineView(.animation(minimumInterval: 1 / 30, paused: model.hint == nil || reduceMotion)) { context in
                    Canvas { canvas, _ in
                        draw(in: canvas, layout: layout, now: context.date)
                    }
                }
                names(layout)
                forgottenLine(layout)
                sparkles(layout)
                // One invisible, untouchable element per star for VoiceOver and the UI tests; the
                // gesture below takes the touches.
                ForEach(model.figure) { star in
                    Color.clear
                        .frame(width: 44, height: 44)
                        .position(layout.point(star.point))
                        .allowsHitTesting(false)
                        .accessibilityElement()
                        .accessibilityLabel(accessibilityLabel(star))
                        .accessibilityValue(accessibilityValue(star))
                        .accessibilityHint(accessibilityHint(star))
                        .accessibilityAddTraits(.isButton)
                        .accessibilityIdentifier("star-\(star.id)")
                        .accessibilityAction { model.tap(star.id) }
                }
            }
            .animation(reduceMotion ? .linear(duration: 0.3) : .easeIn(duration: 0.9), value: model.forgotten)
            .animation(.easeOut(duration: 0.4), value: model.sparkles)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        if model.drag == nil {
                            model.touchBegan(on: layout.nearest(to: value.startLocation, among: model.figure, within: 30), at: value.location)
                        } else {
                            model.touchMoved(to: value.location, over: layout.nearest(to: value.location, among: model.figure, within: 34))
                        }
                    }
                    .onEnded { value in
                        model.touchEnded(on: layout.nearest(to: value.location, among: model.figure, within: 34))
                    }
            )
        }
    }

    // MARK: Layers

    /// The stars around the figure, drawn once: parchment points, the brighter the larger.
    private func backdrop(_ layout: FigureLayout) -> some View {
        Canvas { context, _ in
            for star in model.scene.backdrop {
                let p = layout.point(star.point)
                let radius = max(0.5, 1.9 - 0.25 * star.star.magnitude)
                let opacity = max(0.18, min(0.75, 0.95 - 0.12 * star.star.magnitude))
                context.fill(Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: 2 * radius, height: 2 * radius)),
                             with: .color(Theme.ink.opacity(opacity)))
            }
        }
        .accessibilityHidden(true)
    }

    private func draw(in context: GraphicsContext, layout: FigureLayout, now: Date) {
        let points = Dictionary(uniqueKeysWithValues: model.figure.map { ($0.id, layout.point($0.point)) })

        if showsBorder {
            var border = Path()
            for outline in model.scene.border {
                guard let first = outline.first else { continue }
                border.move(to: layout.point(first))
                for p in outline.dropFirst() { border.addLine(to: layout.point(p)) }
                border.closeSubpath()
            }
            context.stroke(border, with: .color(Theme.lavender.opacity(0.55)),
                           style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [1.5, 6]))
        }

        // The lines drawn, with a soft glow under them.
        var lines = Path()
        for segment in model.drawing.lines {
            guard let a = points[segment.a], let b = points[segment.b] else { continue }
            let (start, end) = trimmed(a, b, by: 9)
            lines.move(to: start)
            lines.addLine(to: end)
        }
        context.stroke(lines, with: .color(Theme.ink.opacity(0.16)), style: StrokeStyle(lineWidth: 6, lineCap: .round))
        context.stroke(lines, with: .color(Theme.ink.opacity(0.92)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

        // The line following the finger.
        if let drag = model.drag, drag.moved, let from = points[drag.from] {
            var live = Path()
            let (start, end) = trimmed(from, drag.at, by: 9)
            live.move(to: start)
            live.addLine(to: end)
            context.stroke(live, with: .color(Theme.ink.opacity(0.6)),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 5]))
        }

        // The figure's stars: a halo, a gold heart, a ring when selected, the glimmer.
        let phase = now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.1) / 1.1
        let pulse = 0.5 - 0.5 * cos(2 * .pi * phase)
        for star in model.figure {
            guard let p = points[star.id] else { continue }
            let radius = max(2.4, 5.2 - 0.8 * star.star.magnitude)
            let halo = radius * 3.2
            context.fill(
                Path(ellipseIn: CGRect(x: p.x - halo, y: p.y - halo, width: 2 * halo, height: 2 * halo)),
                with: .radialGradient(Gradient(colors: [Theme.goldLight.opacity(0.35), Theme.gold.opacity(0)]),
                                      center: p, startRadius: 0, endRadius: halo))
            context.fill(
                Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: 2 * radius, height: 2 * radius)),
                with: .radialGradient(Gradient(colors: [Color(red: 0.984, green: 0.945, blue: 0.824), Theme.goldLight, Theme.gold]),
                                      center: CGPoint(x: p.x - radius * 0.25, y: p.y - radius * 0.3), startRadius: 0, endRadius: radius * 1.1))
            if model.drawing.selected == star.id || model.drag?.target == star.id {
                context.stroke(Path(ellipseIn: CGRect(x: p.x - 13, y: p.y - 13, width: 26, height: 26)),
                               with: .color(Theme.gold.opacity(0.85)), lineWidth: 1)
            }
            if model.hint == star.id {
                let scale = reduceMotion ? 1 : 0.8 + 0.35 * pulse
                let opacity = reduceMotion ? 0.9 : 0.25 + 0.75 * pulse
                let r = 17 * scale
                context.stroke(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)),
                               with: .color(Theme.goldLight.opacity(opacity)),
                               style: StrokeStyle(lineWidth: 1.5, dash: [3, 4]))
            }
        }
    }

    /// The names beside the stars a line has reached.
    private func names(_ layout: FigureLayout) -> some View {
        ForEach(model.figure.filter { model.drawing.namedStars.contains($0.id) }) { star in
            let placement = layout.labelPlacement(for: star, among: model.figure, lines: model.drawing.segments)
            let p = layout.point(star.point)
            // A zero-sized anchor at the point; the name hangs off its side.
            Color.clear
                .frame(width: 0, height: 0)
                .overlay(alignment: placement.anchor.alignment) {
                    Text(verbatim: star.star.label)
                        .font(.system(.callout, design: .serif))
                        .italic()
                        .foregroundStyle(Theme.ink.opacity(0.9))
                        .fixedSize()
                }
                .position(x: p.x + placement.offset.x, y: p.y + placement.offset.y)
                .transition(.opacity)
                .accessibilityHidden(true)
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: model.drawing.namedStars)
    }

    /// A line that didn't belong: lavender, gone in a moment.
    @ViewBuilder
    private func forgottenLine(_ layout: FigureLayout) -> some View {
        if let line = model.forgotten,
           let a = model.figure.first(where: { $0.id == line.from }), let b = model.figure.first(where: { $0.id == line.to }) {
            let (start, end) = trimmed(layout.point(a.point), layout.point(b.point), by: 9)
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(Theme.lavender, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .transition(.asymmetric(insertion: .identity, removal: .opacity))
            .accessibilityHidden(true)
        }
    }

    /// The fill moment's two gold sparkles, at the last star.
    @ViewBuilder
    private func sparkles(_ layout: FigureLayout) -> some View {
        if model.sparkles, let last = model.figure.first(where: { $0.id == model.lastJoined }) {
            let p = layout.point(last.point)
            SparkleView(size: 22, color: Theme.gold, delay: 0)
                .position(x: p.x + 14, y: p.y - 20)
                .transition(.opacity)
            SparkleView(size: 13, color: Theme.goldLight, delay: 0.18)
                .position(x: p.x - 16, y: p.y + 14)
                .transition(.opacity)
        }
    }

    // MARK: Words

    private func accessibilityLabel(_ star: FigureScene.PlacedStar) -> String {
        if model.drawing.namedStars.contains(star.id) || model.isComplete { return star.star.label }
        return String(localized: "voiceover.unnamed-star", defaultValue: "A star of \(model.name)",
                      comment: "VoiceOver's name for a star no line has reached yet; the argument is the constellation's name.")
    }

    private func accessibilityValue(_ star: FigureScene.PlacedStar) -> Text {
        if model.drawing.selected == star.id { return Text("Selected") }
        if model.hint == star.id { return Text("Glimmering") }
        return Text(verbatim: "")
    }

    private func accessibilityHint(_ star: FigureScene.PlacedStar) -> String {
        if model.isComplete { return "" }
        if let selected = model.drawing.selected, selected != star.id {
            return String(localized: "voiceover.hint.join", defaultValue: "Draws a line from \(model.label(selected)).",
                          comment: "VoiceOver hint on a star while another is selected; the argument is the selected star's name.")
        }
        return String(localized: "Starts a line here.")
    }

    /// `a` to `b`, shortened at both ends so lines stop short of the stars.
    private func trimmed(_ a: CGPoint, _ b: CGPoint, by gap: CGFloat) -> (CGPoint, CGPoint) {
        let dx = b.x - a.x, dy = b.y - a.y
        let length = max(hypot(dx, dy), 1)
        let g = min(gap, length / 2)
        return (CGPoint(x: a.x + dx / length * g, y: a.y + dy / length * g),
                CGPoint(x: b.x - dx / length * g, y: b.y - dy / length * g))
    }
}

/// A four-pointed gold sparkle that pops and fades (Paint by Moonlight's fill moment); still,
/// with Reduce Motion.
struct SparkleView: View {
    let size: CGFloat
    let color: Color
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        SparkleShape()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(reduceMotion ? 1 : (shown ? 0.9 : 0.2))
            .rotationEffect(.degrees(reduceMotion ? 0 : (shown ? 10 : -20)))
            .opacity(shown ? 0.95 : 0)
            .onAppear {
                withAnimation(reduceMotion ? .linear(duration: 0.2) : .spring(duration: 0.5, bounce: 0.4).delay(delay)) { shown = true }
            }
            .accessibilityHidden(true)
    }
}

nonisolated struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let pinch = r * 0.12
        var path = Path()
        path.move(to: CGPoint(x: c.x, y: c.y - r))
        path.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: CGPoint(x: c.x + pinch, y: c.y - pinch))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: CGPoint(x: c.x + pinch, y: c.y + pinch))
        path.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: CGPoint(x: c.x - pinch, y: c.y + pinch))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: CGPoint(x: c.x - pinch, y: c.y - pinch))
        path.closeSubpath()
        return path
    }
}
