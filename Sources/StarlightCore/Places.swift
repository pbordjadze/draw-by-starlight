import Foundation

extension Place {
    /// A first guess at where the stargazer is, from the device's time zone: the zone's principal
    /// location in the IANA Time Zone Database (`Resources/zones.tsv`, public domain), good to a
    /// few hundred kilometres, which turns the sky the right way until they pick a city. Nil for a
    /// zone the table doesn't know (a legacy alias, a fixed offset).
    public static func guess(timeZone: TimeZone) -> Place? {
        zones[timeZone.identifier]
    }

    static let zones: [String: Place] = {
        guard let url = Bundle.module.url(forResource: "zones", withExtension: "tsv"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { preconditionFailure("StarlightCore's zones.tsv is unreadable") }
        var zones: [String: Place] = [:]
        for line in text.split(separator: "\n") where !line.hasPrefix("#") {
            let fields = line.split(separator: "\t")
            guard fields.count == 3, let latitude = Double(fields[1]), let longitude = Double(fields[2]) else { continue }
            zones[String(fields[0])] = Place(latitude: latitude, longitude: longitude)
        }
        return zones
    }()
}
