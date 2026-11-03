import StarlightCore
import SwiftUI

/// A figure's night, shown instead of told: the whole sky from where the stargazer is (`Dome`),
/// turning from dusk to dawn as it really will, again and again, the figure's path across it
/// traced faintly. A figure that never sets circles inside the rim; one that rises later comes up
/// over it. VoiceOver reads the night in words.
struct FigureNightView: View {
    let constellation: Constellation
    let sky: Sky
    let place: Place
    /// What VoiceOver reads: where the figure stands tonight.
    let words: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var night: Night?
    @ScaledMetric(relativeTo: .body) private var side: CGFloat = 200

    /// One night, dusk to dawn, takes this long to wheel by.
    private static let seconds = 10.0

    var body: some View {
        Group {
            if let night {
                TimelineView(.animation(paused: reduceMotion)) { context in
                    Canvas { canvas, size in
                        draw(night, at: reduceMotion ? night.evening : night.moment(at: context.date, period: Self.seconds),
                             in: canvas, size: size)
                    }
                }
            }
        }
        .frame(width: side, height: side)
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: words))
        .onAppear {
            if night == nil { night = Night(constellation: constellation, sky: sky, place: place) }
        }
    }

    /// Tonight for one figure, worked out once: dusk, dawn, the sky, and the figure's path.
    private struct Night {
        let constellation: Constellation
        let evening: JulianDay
        let dawn: JulianDay
        let dome: Dome
        /// The figure's middle through the night, on the dome.
        let path: [PlanePoint]

        init(constellation: Constellation, sky: Sky, place: Place) {
            self.constellation = constellation
            evening = FigureScene.evening(from: sky.moment, at: place)
            // Where the Sun never rises again soon (a polar night), half a day.
            let rise = place.nextRise(of: .sun, after: evening)
            dawn = JulianDay(rise.map { min($0.value, evening.value + 1) } ?? evening.value + 0.5)
            dome = Dome(catalogue: sky.catalogue, place: place, around: evening, faintest: 3.5, figures: [constellation])
            let middle = FigureScene.middle(of: constellation.stars.compactMap { sky.catalogue.stars[$0]?.position(at: evening) })
                ?? Equatorial(rightAscension: 0, declination: 0)
            let (start, end) = (evening.value, dawn.value)
            path = (0...96).map { step in
                let t = JulianDay(start + (end - start) * Double(step) / 96)
                return Dome.point(place.horizontal(of: middle, at: t))
            }
        }

        /// The moment shown at `date`: dusk to dawn every `period` seconds.
        func moment(at date: Date, period: Double) -> JulianDay {
            let f = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
            return JulianDay(evening.value + (dawn.value - evening.value) * f)
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
            let magnitude = sky.catalogue.stars[id]?.magnitude ?? 4
            let r = max(1.2, 2.8 - 0.4 * magnitude)
            inside.fill(Path(ellipseIn: CGRect(x: p.x - 2.5 * r, y: p.y - 2.5 * r, width: 5 * r, height: 5 * r)),
                        with: .color(Theme.gold.opacity(0.15)))
            inside.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)),
                        with: .color(Theme.gold))
        }
    }
}
