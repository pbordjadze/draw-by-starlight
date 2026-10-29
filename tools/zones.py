#!/usr/bin/env python3
"""Writes the place of every time zone, for the app's first guess at where the stargazer is.

    tools/zones.py [/usr/share/zoneinfo/zone1970.tab] > Sources/StarlightCore/Resources/zones.tsv

The IANA Time Zone Database's `zone1970.tab` gives each zone's principal location (Paul Eggert
and others; public domain, https://www.iana.org/time-zones). A zone's name is what the device
reports (`TimeZone.current.identifier`), so its location is a real place in the stargazer's zone,
good to a few hundred kilometres: enough to turn the sky the right way until they pick a city
(the place picker is slice 4). The output is checked in; rerun this only to update it.
"""
import sys


def degrees(text):
    """±DDMM[SS] or ±DDDMM[SS] (ISO 6709) to decimal degrees."""
    sign = -1 if text[0] == "-" else 1
    digits = text[1:]
    # Latitude: DDMM or DDMMSS; longitude: DDDMM or DDDMMSS.
    if len(digits) in (4, 6):
        d, m, s = digits[:2], digits[2:4], digits[4:6] or "0"
    else:
        d, m, s = digits[:3], digits[3:5], digits[5:7] or "0"
    return sign * (int(d) + int(m) / 60 + int(s) / 3600)


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "/usr/share/zoneinfo/zone1970.tab"
    print("# zone\tlatitude\tlongitude (IANA tz database, zone1970.tab; public domain)")
    for line in open(path, encoding="utf-8"):
        if line.startswith("#") or not line.strip():
            continue
        _, coordinates, zone = line.rstrip("\n").split("\t")[:3]
        split = max(coordinates.rfind("+"), coordinates.rfind("-"))
        print(f"{zone}\t{degrees(coordinates[:split]):.4f}\t{degrees(coordinates[split:]):.4f}")


if __name__ == "__main__":
    main()
