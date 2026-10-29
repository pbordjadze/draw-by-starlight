import CoreGraphics
import Foundation
import StarlightCore
import SwiftUI

/// Where a scene's points fall in a view: the figure's stars fit inside it with room for their
/// names, up staying up.
nonisolated struct FigureLayout: Equatable {
    let size: CGSize
    /// Points per degree of sky.
    let scale: CGFloat
    let center: CGPoint

    init(size: CGSize, span: Double, inset: CGFloat = 60) {
        self.size = size
        let fit = max(min(size.width, size.height) - 2 * inset, 40)
        scale = fit / CGFloat(2 * span)
        center = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    func point(_ p: PlanePoint) -> CGPoint {
        CGPoint(x: center.x + CGFloat(p.x) * scale, y: center.y - CGFloat(p.y) * scale)
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

    /// Which side of a star its name goes, away from the figure's middle: the offset of the
    /// label's anchor from the star and the anchor to use.
    func labelPlacement(for star: FigureScene.PlacedStar, among figure: [FigureScene.PlacedStar]) -> (offset: CGPoint, anchor: LabelAnchor) {
        let p = point(star.point)
        let n = CGFloat(max(figure.count, 1))
        let middle = figure.reduce(CGPoint.zero) { let q = point($1.point); return CGPoint(x: $0.x + q.x / n, y: $0.y + q.y / n) }
        let dx = p.x - middle.x, dy = p.y - middle.y
        if abs(dx) >= abs(dy) * 0.6 {
            return dx >= 0 ? (CGPoint(x: 16, y: 0), .leading) : (CGPoint(x: -16, y: 0), .trailing)
        }
        return dy >= 0 ? (CGPoint(x: 0, y: 16), .top) : (CGPoint(x: 0, y: -16), .bottom)
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
