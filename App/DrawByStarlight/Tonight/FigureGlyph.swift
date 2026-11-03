import StarlightCore
import SwiftUI

/// A constellation's figure in small, turned as it sits tonight: its stars in gold, the lines
/// drawn so far inked in parchment, the rest only hinted in lavender. Its shape before its name.
struct FigureGlyph: View {
    let scene: FigureScene
    /// The lines inked in, each a pair of Bright Star numbers, the smaller first.
    let inked: Set<[Int]>
    @ScaledMetric(relativeTo: .headline) private var side: CGFloat = 52

    var body: some View {
        Canvas { context, size in
            let layout = FigureLayout(size: size, figure: scene.figure.map(\.point), inset: 4)
            let points = Dictionary(uniqueKeysWithValues: scene.figure.map { ($0.id, layout.point($0.point)) })
            for (a, b) in scene.constellation.segments {
                guard let p = points[a], let q = points[b] else { continue }
                var line = Path()
                line.move(to: p)
                line.addLine(to: q)
                if inked.contains([min(a, b), max(a, b)]) {
                    context.stroke(line, with: .color(Theme.ink.opacity(0.85)), lineWidth: 1.1)
                } else {
                    context.stroke(line, with: .color(Theme.lavender.opacity(0.3)), lineWidth: 0.7)
                }
            }
            for star in scene.figure {
                guard let p = points[star.id] else { continue }
                let r = max(0.9, 2.2 - 0.35 * star.star.magnitude)
                context.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)),
                             with: .color(Theme.gold))
            }
        }
        .frame(width: max(side, 48), height: max(side, 48))
        .accessibilityHidden(true)
    }
}
