import CoreGraphics
import Foundation
import StarlightCore
import SwiftUI

/// Where a scene's points fall in a view: the figure's stars fill it, with room for their names
/// around them, up staying up.
nonisolated struct FigureLayout: Equatable {
    let size: CGSize
    /// Points per degree of sky.
    let scale: CGFloat
    /// The view point of the plane's origin.
    let origin: CGPoint

    /// Fits the figure's stars (`points`, in degrees) inside the view less `inset` on each side.
    init(size: CGSize, figure points: [PlanePoint], inset: CGFloat = 64) {
        self.size = size
        let xs = points.map(\.x), ys = points.map(\.y)
        let minX = xs.min() ?? -1, maxX = xs.max() ?? 1, minY = ys.min() ?? -1, maxY = ys.max() ?? 1
        let width = max(maxX - minX, 0.5), height = max(maxY - minY, 0.5)
        scale = min(max(size.width - 2 * inset, 40) / CGFloat(width), max(size.height - 2 * inset, 40) / CGFloat(height))
        let middle = PlanePoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        origin = CGPoint(x: size.width / 2 - CGFloat(middle.x) * scale, y: size.height / 2 + CGFloat(middle.y) * scale)
    }

    func point(_ p: PlanePoint) -> CGPoint {
        CGPoint(x: origin.x + CGFloat(p.x) * scale, y: origin.y - CGFloat(p.y) * scale)
    }

    /// The figure star nearest a touch, within `radius` points.
    func nearest(to location: CGPoint, among stars: [FigureScene.PlacedStar], within radius: CGFloat) -> Int? {
        var best: (id: Int, distance: CGFloat)?
        for star in stars {
            let p = point(star.point)
            let distance = ((p.x - location.x) * (p.x - location.x) + (p.y - location.y) * (p.y - location.y)).squareRoot()
            if distance <= radius, best == nil || distance < best!.distance { best = (star.id, distance) }
        }
        return best?.id
    }

    /// Which side of a star its name goes: the side farthest from the figure's lines at that star
    /// (drawn or not), and among those, away from the figure's middle. The offset of the label's
    /// anchor from the star, and the anchor to use.
    func labelPlacement(for star: FigureScene.PlacedStar, among figure: [FigureScene.PlacedStar],
                        lines: [FigureDrawing.Segment]) -> (offset: CGPoint, anchor: LabelAnchor) {
        let p = point(star.point)
        let positions = Dictionary(uniqueKeysWithValues: figure.map { ($0.id, point($0.point)) })
        let n = CGFloat(max(figure.count, 1))
        let middle = figure.reduce(CGPoint.zero) { let q = point($1.point); return CGPoint(x: $0.x + q.x / n, y: $0.y + q.y / n) }
        // Unit vectors toward each neighbour the figure joins this star to.
        let neighbours: [CGPoint] = lines.filter { $0.touches(star.id) }.compactMap { line in
            guard let q = positions[line.other(than: star.id)] else { return nil }
            let length = max(hypot(q.x - p.x, q.y - p.y), 1)
            return CGPoint(x: (q.x - p.x) / length, y: (q.y - p.y) / length)
        }
        let away = CGPoint(x: p.x - middle.x, y: p.y - middle.y)
        let sides: [(side: CGPoint, offset: CGPoint, anchor: LabelAnchor)] = [
            (CGPoint(x: 1, y: 0), CGPoint(x: 16, y: 0), .leading),
            (CGPoint(x: -1, y: 0), CGPoint(x: -16, y: 0), .trailing),
            (CGPoint(x: 0, y: 1), CGPoint(x: 0, y: 16), .top),
            (CGPoint(x: 0, y: -1), CGPoint(x: 0, y: -16), .bottom),
        ]
        // A line within about 50° of a side crowds it; the rest is a preference for the outside.
        let best = sides.min { a, b in
            let crowdA = neighbours.map { $0.x * a.side.x + $0.y * a.side.y }.max() ?? -1
            let crowdB = neighbours.map { $0.x * b.side.x + $0.y * b.side.y }.max() ?? -1
            let outA = max(crowdA, 0.64) - 0.1 * (away.x * a.side.x + away.y * a.side.y) / max(hypot(away.x, away.y), 1)
            let outB = max(crowdB, 0.64) - 0.1 * (away.x * b.side.x + away.y * b.side.y) / max(hypot(away.x, away.y), 1)
            return outA < outB
        }!
        return (best.offset, best.anchor)
    }

    /// The side of its anchor point a label sits on.
    enum LabelAnchor {
        case leading, trailing, top, bottom

        /// The label's edge that meets the point.
        var alignment: Alignment {
            switch self {
            case .leading: .leading
            case .trailing: .trailing
            case .top: .top
            case .bottom: .bottom
            }
        }
    }
}
