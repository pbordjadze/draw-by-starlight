#!/usr/bin/env python3
"""Builds StarlightCore's bundled sky from its published sources.

    tools/sky_data.py <download dir>

Downloads what the download dir doesn't hold yet, then writes `Sources/StarlightCore/Resources/`:

  stars.tsv         every star of the Yale Bright Star Catalogue, 5th revised edition (Hoffleit &
                    Warren 1991; to about magnitude 6.5): HR number, J2000 right ascension and
                    declination (degrees), proper motion (arcsec a year, RA's projected), V
                    magnitude, B-V, Bayer letter or Flamsteed number, constellation. NASA's HEASARC
                    distributes it as a U.S. Government Work (catalog.data.gov, "bright star
                    catalog"); the file read here is the identical CDS copy, VizieR V/50.
  names.tsv         HR number and proper name, from the IAU Catalog of Star Names (IAU WGSN;
                    "All IAU-produced products ... are released under Creative Commons
                    Attribution", the file's header).
  figures.tsv       each constellation's abbreviation, Latin name, and its figure's lines as chains
                    of HR numbers. The lines are d3-celestial's (Olaf Frohn, BSD 3-Clause License),
                    drawn after the IAU's constellation charts (IAU and Sky & Telescope, Roger
                    Sinnott and Rick Fienberg; Creative Commons Attribution). d3-celestial gives
                    each line's stars by position: each is matched to the nearest catalogue star.
  borders.tsv       each constellation's border as the IAU defined it (Delporte, *Délimitation
                    scientifique des constellations*, 1930), its corners at the equinox of B1875,
                    from the Catalogue of Constellation Boundary Data (Davenhall & Leggett 1989,
                    VizieR VI/49). Serpens has two parts.

The output is checked in, so the app and CI never download anything; rerun this only to change it.
Every source is credited in `Sources/StarlightCore/Resources/CREDITS.md`.
"""
import gzip
import json
import math
import os
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "Sources", "StarlightCore", "Resources")

SOURCES = {
    "catalog.gz": "https://cdsarc.cds.unistra.fr/ftp/V/50/catalog.gz",
    "IAU-CSN.txt": "https://www.pas.rochester.edu/~emamajek/WGSN/IAU-CSN.txt",
    "constellations.lines.json": "https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.lines.json",
    "constellations.json": "https://raw.githubusercontent.com/ofrohn/d3-celestial/master/data/constellations.json",
    "bound_18.dat": "https://cdsarc.cds.unistra.fr/ftp/VI/49/bound_18.dat",
}

GREEK = {
    "Alp": "α", "Bet": "β", "Gam": "γ", "Del": "δ", "Eps": "ε", "Zet": "ζ", "Eta": "η", "The": "θ",
    "Iot": "ι", "Kap": "κ", "Lam": "λ", "Mu": "μ", "Nu": "ν", "Xi": "ξ", "Omi": "ο", "Pi": "π",
    "Rho": "ρ", "Sig": "σ", "Tau": "τ", "Ups": "υ", "Phi": "φ", "Chi": "χ", "Psi": "ψ", "Ome": "ω",
}
# Matching a line's end to a catalogue star: d3-celestial's positions are Hipparcos's, at its
# 1991.25 epoch; a star this far off is not the same star.
MATCH_DEGREES = 0.1


def fetch(folder):
    os.makedirs(folder, exist_ok=True)
    for name, url in SOURCES.items():
        path = os.path.join(folder, name)
        if not os.path.exists(path):
            print("downloading", url)
            urllib.request.urlretrieve(url, path)
    return {name: os.path.join(folder, name) for name in SOURCES}


def number(text):
    text = text.strip()
    return float(text) if text else None


def designation(name):
    """'16Alp Boo' → ('α', 'Boo'); '58    Ori' → ('58', 'Ori'); a superscript digit kept: 'α1'."""
    flamsteed, letters, constellation = name[0:3].strip(), name[3:7].strip(), name[7:10].strip()
    if letters:
        base, index = letters.rstrip("0123456789"), letters[len(letters.rstrip("0123456789")):]
        if base in GREEK:
            return GREEK[base] + index.lstrip("0"), constellation
        return letters, constellation
    return flamsteed, constellation


def stars(path):
    rows = []
    with gzip.open(path, "rt", encoding="latin-1") as f:
        for line in f:
            line = line.rstrip("\n").ljust(197)
            if not line[75:77].strip():
                continue  # one of the 14 novae and galaxies the numbering keeps
            hr = int(line[0:4])
            ra = (int(line[75:77]) + int(line[77:79]) / 60 + float(line[79:83]) / 3600) * 15
            dec = int(line[84:86]) + int(line[86:88]) / 60 + int(line[88:90]) / 3600
            if line[83] == "-":
                dec = -dec
            letter, constellation = designation(line[4:14])
            rows.append({
                "hr": hr, "ra": ra, "dec": dec,
                "pmra": number(line[148:154]) or 0.0, "pmdec": number(line[154:160]) or 0.0,
                "vmag": number(line[102:107]), "bv": number(line[109:114]),
                "letter": letter, "constellation": constellation,
            })
    return rows


def names(path):
    result = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            if line.startswith(("#", "$")) or not line.strip():
                continue
            # Columns are fixed-width; the name with diacritics is the second, the designation third.
            parts = line.split()
            name, designation_ = line[18:36].strip(), line[36:49].strip()
            if designation_.startswith("HR "):
                result.setdefault(int(designation_[3:]), name or parts[0])
    return result


def separation(ra1, dec1, ra2, dec2):
    r = math.radians
    c = (math.sin(r(dec1)) * math.sin(r(dec2))
         + math.cos(r(dec1)) * math.cos(r(dec2)) * math.cos(r(ra1 - ra2)))
    return math.degrees(math.acos(max(-1.0, min(1.0, c))))


def figures(lines_path, names_path, catalogue):
    latin = {f["id"]: f["properties"]["name"] for f in json.load(open(names_path))["features"]}
    by_band = {}
    for star in catalogue:
        by_band.setdefault(int(star["dec"]), []).append(star)

    def nearest(ra, dec):
        best, best_distance = None, MATCH_DEGREES
        for band in range(int(dec) - 1, int(dec) + 2):
            for star in by_band.get(band, []):
                distance = separation(ra, dec, star["ra"], star["dec"])
                if distance < best_distance:
                    best, best_distance = star, distance
        return best

    result, missing = {}, []
    for feature in json.load(open(lines_path))["features"]:
        abbreviation = feature["id"]
        for chain in feature["geometry"]["coordinates"]:
            stars_ = []
            for lon, lat in chain:
                star = nearest(lon % 360, lat)
                if star is None:
                    missing.append((abbreviation, lon % 360, lat))
                    continue
                stars_.append(star["hr"])
            if len(stars_) > 1:
                result.setdefault(abbreviation, []).append(stars_)
    if missing:
        sys.exit(f"line ends with no catalogue star within {MATCH_DEGREES}°: {missing}")
    return [(a, latin[a], result[a]) for a in sorted(result)]


def borders(path):
    parts = []
    with open(path) as f:
        for line in f:
            ra, dec, name = float(line[0:8]) * 15, float(line[9:18]), line[19:23].strip()
            if not parts or parts[-1][0] != name:
                parts.append((name, []))
            parts[-1][1].append((ra, dec))
    return parts


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    paths = fetch(sys.argv[1])
    catalogue = stars(paths["catalog.gz"])
    star_names = names(paths["IAU-CSN.txt"])
    known = {s["hr"] for s in catalogue}
    os.makedirs(OUT, exist_ok=True)

    def text(value, digits):
        return "" if value is None else f"{value:.{digits}f}"

    with open(os.path.join(OUT, "stars.tsv"), "w", encoding="utf-8") as f:
        f.write("# hr\tra\tdec\tpmra\tpmdec\tvmag\tbv\tletter\tconstellation\n")
        for s in catalogue:
            f.write("\t".join([
                str(s["hr"]), f"{s['ra']:.5f}", f"{s['dec']:.5f}", f"{s['pmra']:.3f}", f"{s['pmdec']:.3f}",
                text(s["vmag"], 2), text(s["bv"], 2), s["letter"], s["constellation"],
            ]) + "\n")
    with open(os.path.join(OUT, "names.tsv"), "w", encoding="utf-8") as f:
        f.write("# hr\tname\n")
        for hr in sorted(star_names):
            if hr in known:
                f.write(f"{hr}\t{star_names[hr]}\n")
    with open(os.path.join(OUT, "figures.tsv"), "w", encoding="utf-8") as f:
        f.write("# abbreviation\tname\tlines (HR numbers, '-' within a line, ' ' between lines)\n")
        for abbreviation, name, chains in figures(paths["constellations.lines.json"], paths["constellations.json"], catalogue):
            f.write(f"{abbreviation}\t{name}\t{' '.join('-'.join(map(str, c)) for c in chains)}\n")
    with open(os.path.join(OUT, "borders.tsv"), "w", encoding="utf-8") as f:
        f.write("# part\tcorners at B1875 (ra,dec degrees; ' ' between corners)\n")
        for name, corners in borders(paths["bound_18.dat"]):
            f.write(f"{name}\t{' '.join(f'{ra:.5f},{dec:.5f}' for ra, dec in corners)}\n")


if __name__ == "__main__":
    main()
