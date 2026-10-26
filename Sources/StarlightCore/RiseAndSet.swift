import Foundation

/// Something in the sky that rises and sets.
public enum SkyObject: Sendable {
    case star(Star)
    case sun
    case moon

    /// Its right ascension and declination for the equator and equinox of `moment`, seen from the
    /// Earth's center.
    public func position(at moment: JulianDay) -> Equatorial {
        switch self {
        case .star(let star): star.position(at: moment)
        case .sun: Sun(at: moment).position
        case .moon: Moon(at: moment).position
        }
    }

    /// The geocentric altitude, in degrees, at which it rises or sets: its upper limb on a
    /// sea-level horizon, lifted by the standard 34′ of refraction (Meeus, *Astronomical
    /// Algorithms*, 15.1; the Moon's from its parallax).
    func standardAltitude(at moment: JulianDay) -> Double {
        switch self {
        case .star: -0.5667
        case .sun: -0.8333
        case .moon: 0.7275 * Moon(at: moment).parallax - 0.5667
        }
    }
}

extension Place {
    /// Where `object` stands in this place's sky at `moment`, without refraction; the Moon as seen
    /// from here rather than from the Earth's center.
    public func horizontal(of object: SkyObject, at moment: JulianDay) -> Horizontal {
        switch object {
        case .moon: Moon(at: moment).horizontal(in: self, at: moment)
        default: horizontal(of: object.position(at: moment), at: moment)
        }
    }

    /// The first moment after `moment`, within two days, at which `object` rises here: nil when it
    /// stays below or above the horizon all that time.
    public func nextRise(of object: SkyObject, after moment: JulianDay) -> JulianDay? {
        crossings(of: object, from: moment, days: 2).first { $0.rising }?.moment
    }

    /// The first moment after `moment`, within two days, at which `object` sets here.
    public func nextSet(of object: SkyObject, after moment: JulianDay) -> JulianDay? {
        crossings(of: object, from: moment, days: 2).first { !$0.rising }?.moment
    }

    private func crossings(of object: SkyObject, from start: JulianDay, days: Double) -> [Crossing] {
        let end = JulianDay(start.value + days)
        switch object {
        case .star(let star):
            // A star's place barely moves in two days: precess once.
            let position = star.position(at: JulianDay(start.value + days / 2))
            let standard = object.standardAltitude(at: start)
            return crossings(from: start, to: end) { _ in (position, standard) }
        case .sun:
            return crossings(from: start, to: end) { (Sun(at: $0).position, object.standardAltitude(at: $0)) }
        case .moon:
            return crossings(from: start, to: end) {
                let moon = Moon(at: $0)
                return (moon.position, 0.7275 * moon.parallax - 0.5667)
            }
        }
    }

    struct Crossing {
        let moment: JulianDay
        let rising: Bool
    }

    /// Every moment in (start, end] at which a body whose place and standard altitude `body` gives
    /// crosses that altitude, in order: sampled every ten minutes, then halved down to a second. A
    /// body that only grazes the horizon, rising and setting within one ten-minute step (possible
    /// only far north or south), is missed.
    func crossings(from start: JulianDay, to end: JulianDay, body: (JulianDay) -> (Equatorial, Double)) -> [Crossing] {
        func height(_ t: Double) -> Double {
            let (position, standard) = body(JulianDay(t))
            return horizontal(of: position, at: JulianDay(t)).altitude - standard
        }
        let step = 10.0 / 1440
        var result: [Crossing] = []
        var t0 = start.value, h0 = height(t0)
        while t0 < end.value {
            let t1 = min(t0 + step, end.value), h1 = height(t1)
            if (h0 < 0) != (h1 < 0) {
                var low = t0, high = t1
                while high - low > 1.0 / 86_400 {
                    let middle = (low + high) / 2
                    if (height(middle) < 0) == (h0 < 0) { low = middle } else { high = middle }
                }
                result.append(Crossing(moment: JulianDay((low + high) / 2), rising: h0 < 0))
            }
            t0 = t1
            h0 = h1
        }
        return result
    }
}
