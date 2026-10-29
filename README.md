# Draw by Starlight

An iPhone app where you learn the constellations and the night sky by drawing them, star to star,
in tonight's real sky. Working name. Work in progress.

## Trying it

CI builds an unsigned IPA from `main` and publishes a SideStore source: add
`https://raw.githubusercontent.com/pbordjadze/draw-by-starlight/sidestore/source.json` in
SideStore (Sources → +). A work in progress: so far you can draw sixteen constellations as they
sit in tonight's sky and read each one's story, quoted from Wikipedia.

## Privacy

No account, no server, no network, no analytics, no ads. Everything stays on your iPhone. See
[PRIVACY.md](PRIVACY.md).

## Building

Swift 6, SwiftUI, iOS 26. `StarlightCore` (the sky's computations) builds and tests on Linux:
`tools/swift.sh test`. The app builds on CI; see [CLAUDE.md](CLAUDE.md).
