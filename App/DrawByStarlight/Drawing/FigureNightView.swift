import StarlightCore
import SwiftUI

/// A figure's night, shown instead of told: the whole sky from where the stargazer is (`Dome`),
/// turning from sunset to sunrise (`FigureScene.night`) as it really will, again and again, the
/// figure's path across it traced faintly. A figure that never sets circles inside the rim; one
/// that rises later comes up over it. VoiceOver reads the night in words.
struct FigureNightView: View {
    /// What VoiceOver reads: where the figure stands tonight.
    let words: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var night: Night

    /// `still` is the moment shown without motion: the figure's own, up (`FigureScene.moment`).
    init(constellation: Constellation, sky: Sky, place: Place, still: JulianDay, words: String) {
        self.words = words
        _night = State(initialValue: Night(constellation: constellation, sky: sky, place: place, still: still))
    }

    /// One night, sunset to sunrise, takes this long to wheel by.
    private static let seconds = 10.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: still)) { context in
            Canvas { canvas, size in
                let (moment, opacity) = still ? (night.still, 1.0) : night.moment(at: context.date, period: Self.seconds)
                var faded = canvas
                faded.opacity = opacity
                draw(night, at: moment, in: faded, size: size)
            }
        }
        // A picture, not text: it doesn't grow with the text size.
        .frame(maxWidth: 220)
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: words))
        .accessibilityAddTraits(.isImage)
    }

    /// Still with Reduce Motion, and in a demo scenario, so its screenshot is the same each time.
    private var still: Bool {
        #if DEBUG
        if DemoMode.isActive { return true }
        #endif
        return reduceMotion
    }

    /// Tonight for one figure, worked out once: dusk, dawn, the sky, and the figure's path.
    private struct Night {
        let constellation: Constellation
        let evening: JulianDay
        let dawn: JulianDay
        let still: JulianDay
        let dome: Dome
        /// The figure's stars' magnitudes, for their sizes.
        let magnitudes: [Int: Double]
        /// The figure's middle through the night, on the dome.
        let path: [PlanePoint]

        init(constellation: Constellation, sky: Sky, place: Place, still: JulianDay) {
            self.constellation = constellation
            (evening, dawn) = FigureScene.night(from: sky.moment, at: place)
            self.still = still
            magnitudes = Dictionary(uniqueKeysWithValues: constellation.stars.compactMap { id in
                sky.catalogue.stars[id].map { (id, $0.magnitude) }
            })
            dome = Dome(catalogue: sky.catalogue, place: place, around: evening, faintest: 3.5, figures: [constellation])
            let middle = FigureScene.middle(of: constellation.stars.compactMap { sky.catalogue.stars[$0]?.position(at: evening) })
                ?? Equatorial(rightAscension: 0, declination: 0)
            let (start, end) = (evening.value, dawn.value)
            path = (0...96).map { step in
                let t = JulianDay(start + (end - start) * Double(step) / 96)
                return Dome.point(place.horizontal(of: middle, at: t))
            }
        }

        /// The moment shown at `date`, dusk to dawn every `period` seconds, and how much to show:
        /// the night fades out at dawn and in again at dusk, rather than the sky snapping back.
        func moment(at date: Date, period: Double) -> (JulianDay, Double) {
            let f = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
            let fade = 0.06
            return (JulianDay(evening.value + (dawn.value - evening.value) * f), min(1, f / fade, (1 - f) / fade))
        }
    }

    private func draw(_ night: Night, at moment: JulianDay, in context: GraphicsContext, size: CGSize) {
        let radius = min(size.width, size.height) / 2 - 2
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        func point(_ p: PlanePoint) -> CGPoint {
            CGPoint(x: center.x + CGFloat(p.x) * radius, y: center.y - CGFloat(p.y) * radius)
        }
        var rim = Path()
        rim.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: 2 * radius, height: 2 * radius))
        context.fill(rim, with: .radialGradient(
            Gradient(colors: [Theme.surface.opacity(0.7), Theme.paper.opacity(0)]),
            center: center, startRadius: 0, endRadius: radius))
        context.stroke(rim, with: .color(Theme.lavender.opacity(0.35)), lineWidth: 0.8)

        var inside = context
        inside.clip(to: rim)
        // The bright stars, turning with it.
        let own = Set(night.constellation.stars)
        var stars = Path()
        for star in night.dome.visible(at: moment) where !own.contains(star.star.id) {
            let p = point(star.point)
            let r = max(0.5, 1.4 - 0.25 * star.star.magnitude)
            stars.addEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r))
        }
        inside.fill(stars, with: .color(Theme.ink.opacity(0.45)))

        // Its path tonight.
        var trail = Path()
        if let first = night.path.first {
            trail.move(to: point(first))
            for p in night.path.dropFirst() { trail.addLine(to: point(p)) }
        }
        inside.stroke(trail, with: .color(Theme.lavender.opacity(0.45)),
                      style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [1.5, 5]))

        // The figure, whole.
        var points: [Int: CGPoint] = [:]
        for id in night.constellation.stars {
            if let p = night.dome.point(of: id, at: moment) { points[id] = point(p) }
        }
        var lines = Path()
        for (a, b) in night.constellation.segments {
            guard let p = points[a], let q = points[b] else { continue }
            lines.move(to: p)
            lines.addLine(to: q)
        }
        inside.stroke(lines, with: .color(Theme.ink.opacity(0.9)), lineWidth: 1.3)
        for (id, p) in points {
            let magnitude = night.magnitudes[id] ?? 4
            let r = max(1.2, 2.8 - 0.4 * magnitude)
            inside.fill(Path(ellipseIn: CGRect(x: p.x - 2.5 * r, y: p.y - 2.5 * r, width: 5 * r, height: 5 * r)),
                        with: .color(Theme.gold.opacity(0.15)))
            inside.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)),
                        with: .color(Theme.gold))
        }
    }
}
