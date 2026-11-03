import Foundation
import StarlightCore

/// Words for where something stands in the sky.
nonisolated enum SkyWords {
    /// The compass point nearest an azimuth: "north", "northeast", …
    static func direction(azimuth: Double) -> String {
        switch Int(((azimuth + 22.5).truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) / 45) {
        case 0: String(localized: "north")
        case 1: String(localized: "northeast")
        case 2: String(localized: "east")
        case 3: String(localized: "southeast")
        case 4: String(localized: "south")
        case 5: String(localized: "southwest")
        case 6: String(localized: "west")
        default: String(localized: "northwest")
        }
    }

    /// How high an altitude is: "high" (50° and up), "halfway up", "low" (under 25°).
    static func height(altitude: Double) -> String {
        switch altitude {
        case 50...: String(localized: "high")
        case 25..<50: String(localized: "halfway up")
        default: String(localized: "low")
        }
    }

    /// Where a figure stands, in a few words: "High in the northeast", "Rises later; highest at
    /// 2:15 AM", "Never rises from here".
    static func listing(_ scene: FigureScene, place: Place?, time: (JulianDay) -> String) -> String {
        switch scene.timing {
        case .now:
            let center = scene.center ?? Horizontal(altitude: 0, azimuth: 0)
            let height = height(altitude: center.altitude)
            let capitalized = height.prefix(1).uppercased() + String(height.dropFirst())
            return String(localized: "list.standing.now",
                defaultValue: "\(capitalized) in the \(direction(azimuth: center.azimuth))",
                comment: "Where a constellation stands, read by VoiceOver on the home screen's sky; the arguments are a capitalized height word (High, Halfway up, Low) and a compass direction.")
        case .later(let transit):
            return String(localized: "list.standing.later",
                defaultValue: "Rises later; highest at \(time(transit))",
                comment: "Where a constellation stands, read by VoiceOver on the home screen's sky, when it hasn't risen yet; the argument is a clock time.")
        case .beforeDawn(let moment):
            return String(localized: "list.standing.dawn",
                defaultValue: "Rises later; before dawn at \(time(moment))",
                comment: "Where a constellation stands, read by VoiceOver on the home screen's sky, when it rises after midnight and is highest in daylight; the argument is a clock time, an hour before sunrise.")
        case .notTonight:
            return String(localized: "Not up tonight")
        case .unseen:
            return place == nil ? String(localized: "Place unknown") : String(localized: "Never rises from here")
        }
    }
}
