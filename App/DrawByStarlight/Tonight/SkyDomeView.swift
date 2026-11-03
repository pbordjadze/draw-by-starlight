import StarlightCore
import SwiftUI

/// Tonight's whole sky, as a planisphere shows it (`Dome`): the zenith in the middle, the horizon
/// the rim, north up and east on the left. The figures that are up sit where they are, their
/// stars in gold and their lines only hinted until drawn; a figure is named once it's drawn.
/// Opening, the sky wheels through the last two hours to tonight, as it really turned. The
/// figures below the horizon wait under the rim. A touch on a figure opens it.
struct SkyDomeView: View {
    let sky: Sky
    let drawn: DrawnFigures
    let open: (String) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var night: Night?
    @State private var opened = Date.now
    @State private var settled = false

    /// The sky turns through this much of the evening, in days, as the home screen opens.
    private static let lapse = 2.0 / 24
    private static let lapseSeconds = 4.0

    var body: some View {
        VStack(spacing: 20) {
            if let night {
                if let dome = night.dome {
                    // Read here, so a figure drawn since redraws the sky.
                    let marks = Marks(
                        inked: Dictionary(uniqueKeysWithValues: night.up.map { ($0.id, drawn.inked($0)) }),
                        named: Set(night.up.map(\.id).filter(drawn.isDrawn)))
                    GeometryReader { geometry in
                        let disc = Disc(size: geometry.size)
                        ZStack {
                            TimelineView(.animation(paused: settled)) { context in
                                Canvas { canvas, _ in
                                    draw(dome, night: night, marks: marks, at: moment(night.evening, now: context.date), in: canvas, disc: disc)
                                }
                            }
                            .accessibilityHidden(true)
                            cardinals(disc)
                            figureElements(dome, night: night, marks: marks, disc: disc)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture(coordinateSpace: .local) { location in
                            if let id = figure(near: location, dome: dome, night: night, disc: disc) { open(id) }
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
                below(night.down)
            }
        }
        .padding(.horizontal, 12)
        .onChange(of: sky.now, initial: true) {
            night = Night(sky: sky)
        }
        .task {
            guard !settled else { return }
            if !reduceMotion, sky.place != nil {
                opened = .now
                try? await Task.sleep(for: .seconds(Self.lapseSeconds))
            }
            settled = true
            #if DEBUG
            // A drawing's scenario is ready when the drawing is (`DrawingView`).
            if DemoMode.scenario?.hasPrefix("draw-") == false { DemoMode.markReady() }
            #endif
        }
    }

    // MARK: The night

    /// Tonight, worked out once: where it starts, the sky, and which figures are up.
    private struct Night {
        let evening: JulianDay
        let dome: Dome?
        /// The figures up tonight.
        let up: [Constellation]
        /// The rest, as they'll stand: the ones rising later, soonest first, then the ones not
        /// up tonight.
        let down: [FigureScene]

        init(sky: Sky) {
            let scenes = sky.drawable.map { sky.scene($0, backdrop: false) }
            up = scenes.filter { $0.timing == .now }.map(\.constellation)
            down = scenes.filter { $0.timing != .now }.sorted { a, b in
                switch (Self.rising(a), Self.rising(b)) {
                case (let x?, let y?): x < y
                case (.some, nil): true
                case (nil, .some): false
                case (nil, nil): a.constellation.name < b.constellation.name
                }
            }
            if let place = sky.place {
                evening = FigureScene.evening(from: sky.moment, at: place)
                dome = Dome(catalogue: sky.catalogue, place: place, around: evening, figures: up)
            } else {
                evening = sky.moment
                dome = nil
            }
        }

        private static func rising(_ scene: FigureScene) -> JulianDay? {
            switch scene.timing {
            case .later(let moment), .beforeDawn(let moment): moment
            default: nil
            }
        }
    }

    /// What's drawn of the figures up: the lines to ink, and the figures to name.
    private struct Marks {
        let inked: [String: Set<[Int]>]
        let named: Set<String>
    }

    /// Under the rim, the figures below the horizon, dimmer, turned as they'll stand.
    private func below(_ scenes: [FigureScene]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 18) {
                ForEach(scenes, id: \.constellation.id) { scene in
                    Button {
                        open(scene.constellation.id)
                    } label: {
                        FigureGlyph(scene: scene, inked: drawn.inked(scene.constellation), side: 60)
                            .opacity(0.7)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: scene.constellation.name))
                    .accessibilityValue(drawn.isDrawn(scene.constellation.id) ? Text("Drawn") : Text(verbatim: ""))
                    .accessibilityIdentifier("figure-\(scene.constellation.id)")
                }
            }
            .padding(.horizontal, 8)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Drawing

    /// The disc of the sky inside the view.
    private struct Disc {
        let center: CGPoint
        let radius: CGFloat

        init(size: CGSize) {
            center = CGPoint(x: size.width / 2, y: size.height / 2)
            // Room for the compass letters around the rim.
            radius = max(10, min(size.width, size.height) / 2 - 18)
        }

        func point(_ p: PlanePoint) -> CGPoint {
            CGPoint(x: center.x + CGFloat(p.x) * radius, y: center.y - CGFloat(p.y) * radius)
        }

        func points(of constellation: Constellation, on dome: Dome, at moment: JulianDay) -> [Int: CGPoint] {
            var points: [Int: CGPoint] = [:]
            for id in constellation.stars {
                if let p = dome.point(of: id, at: moment) { points[id] = point(p) }
            }
            return points
        }
    }

    /// The moment shown: the last two hours wheeling by as the screen opens, then the evening.
    private func moment(_ evening: JulianDay, now: Date) -> JulianDay {
        guard !settled else { return evening }
        let f = min(1, max(0, now.timeIntervalSince(opened) / Self.lapseSeconds))
        let eased = 1 - pow(1 - f, 3)
        return JulianDay(evening.value - Self.lapse * (1 - eased))
    }

    private func draw(_ dome: Dome, night: Night, marks: Marks, at moment: JulianDay, in context: GraphicsContext, disc: Disc) {
        var rim = Path()
        rim.addEllipse(in: CGRect(x: disc.center.x - disc.radius, y: disc.center.y - disc.radius,
                                  width: 2 * disc.radius, height: 2 * disc.radius))
        context.fill(rim, with: .radialGradient(
            Gradient(colors: [Theme.surface.opacity(0.6), Theme.paper.opacity(0)]),
            center: disc.center, startRadius: 0, endRadius: disc.radius))
        context.stroke(rim, with: .color(Theme.lavender.opacity(0.3)), lineWidth: 0.8)

        var inside = context
        inside.clip(to: rim)
        let own = Set(night.up.flatMap(\.stars))
        for star in dome.visible(at: moment) where !own.contains(star.star.id) {
            let p = disc.point(star.point)
            let r = max(0.45, 1.6 - 0.25 * star.star.magnitude)
            let opacity = max(0.2, min(0.8, 1 - 0.15 * star.star.magnitude))
            inside.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)),
                        with: .color(Theme.ink.opacity(opacity)))
        }

        for constellation in night.up {
            let inked = marks.inked[constellation.id] ?? []
            let points = disc.points(of: constellation, on: dome, at: moment)
            for (a, b) in constellation.segments {
                guard let p = points[a], let q = points[b] else { continue }
                var line = Path()
                line.move(to: p)
                line.addLine(to: q)
                if inked.contains([min(a, b), max(a, b)]) {
                    inside.stroke(line, with: .color(Theme.ink.opacity(0.85)), lineWidth: 1.2)
                } else {
                    inside.stroke(line, with: .color(Theme.lavender.opacity(0.4)), lineWidth: 0.8)
                }
            }
            for id in constellation.stars {
                guard let p = points[id], let star = sky.catalogue.stars[id] else { continue }
                let r = max(1, 2.6 - 0.4 * star.magnitude)
                inside.fill(Path(ellipseIn: CGRect(x: p.x - 2.5 * r, y: p.y - 2.5 * r, width: 5 * r, height: 5 * r)),
                            with: .color(Theme.gold.opacity(0.12)))
                inside.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)),
                            with: .color(Theme.gold))
            }
            // A figure is named once it's drawn: the sky fills with what's been learned.
            if marks.named.contains(constellation.id), let lowest = points.values.map(\.y).max() {
                let x = points.values.map(\.x).reduce(0, +) / CGFloat(points.count)
                inside.draw(Text(verbatim: constellation.name)
                                .font(.system(.footnote, design: .serif).italic())
                                .foregroundStyle(Theme.ink.opacity(0.9)),
                            at: CGPoint(x: x, y: lowest + 14))
            }
        }
    }

    /// N, E, S and W just outside the rim, where those horizons are.
    private func cardinals(_ disc: Disc) -> some View {
        ZStack {
            cardinal(Text("N"), at: CGPoint(x: disc.center.x, y: disc.center.y - disc.radius - 10))
            cardinal(Text("E"), at: CGPoint(x: disc.center.x - disc.radius - 10, y: disc.center.y))
            cardinal(Text("S"), at: CGPoint(x: disc.center.x, y: disc.center.y + disc.radius + 10))
            cardinal(Text("W"), at: CGPoint(x: disc.center.x + disc.radius + 10, y: disc.center.y))
        }
        .accessibilityHidden(true)
    }

    private func cardinal(_ letter: Text, at point: CGPoint) -> some View {
        letter
            .font(.system(.caption2, design: .serif))
            .foregroundStyle(Theme.lavender.opacity(0.8))
            .position(point)
    }

    // MARK: Touch and VoiceOver

    /// One element per figure up, at its middle, for VoiceOver and the UI tests; touches go to the
    /// dome's tap.
    private func figureElements(_ dome: Dome, night: Night, marks: Marks, disc: Disc) -> some View {
        ForEach(night.up, id: \.id) { constellation in
            let points = Array(disc.points(of: constellation, on: dome, at: night.evening).values)
            if !points.isEmpty {
                Color.clear
                    .frame(width: 44, height: 44)
                    .position(x: points.map(\.x).reduce(0, +) / CGFloat(points.count),
                              y: points.map(\.y).reduce(0, +) / CGFloat(points.count))
                    .allowsHitTesting(false)
                    .accessibilityElement()
                    .accessibilityLabel(Text(verbatim: constellation.name))
                    .accessibilityValue(marks.named.contains(constellation.id) ? Text("Drawn") : Text(verbatim: ""))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("figure-\(constellation.id)")
                    .accessibilityAction { open(constellation.id) }
            }
        }
    }

    /// The figure up with a line nearest a touch, within reach of a finger.
    private func figure(near location: CGPoint, dome: Dome, night: Night, disc: Disc) -> String? {
        var best: (id: String, distance: CGFloat)?
        for constellation in night.up {
            let points = disc.points(of: constellation, on: dome, at: night.evening)
            for (a, b) in constellation.segments {
                guard let p = points[a], let q = points[b] else { continue }
                let d = Self.distance(from: location, toSegment: p, q)
                if d <= 28, best.map({ d < $0.distance }) ?? true { best = (constellation.id, d) }
            }
        }
        return best?.id
    }

    private nonisolated static func distance(from c: CGPoint, toSegment a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        let length = dx * dx + dy * dy
        let t = length == 0 ? 0 : max(0, min(1, ((c.x - a.x) * dx + (c.y - a.y) * dy) / length))
        let x = a.x + t * dx - c.x, y = a.y + t * dy - c.y
        return (x * x + y * y).squareRoot()
    }
}
