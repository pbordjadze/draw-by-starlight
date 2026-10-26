import Foundation

// Trigonometry in degrees: StarlightCore's angles are degrees throughout (CLAUDE.md › The sky).

func sin(degrees: Double) -> Double { sin(degrees * .pi / 180) }
func cos(degrees: Double) -> Double { cos(degrees * .pi / 180) }
func tan(degrees: Double) -> Double { tan(degrees * .pi / 180) }
func asinDegrees(_ x: Double) -> Double { asin(max(-1, min(1, x))) * 180 / .pi }
func acosDegrees(_ x: Double) -> Double { acos(max(-1, min(1, x))) * 180 / .pi }
func atan2Degrees(_ y: Double, _ x: Double) -> Double { atan2(y, x) * 180 / .pi }

extension Double {
    /// The angle in [0, 360).
    var normalizedDegrees: Double {
        let r = truncatingRemainder(dividingBy: 360)
        return r < 0 ? r + 360 : r
    }

    /// The angle in [-180, 180).
    var signedDegrees: Double {
        let r = normalizedDegrees
        return r >= 180 ? r - 360 : r
    }
}
