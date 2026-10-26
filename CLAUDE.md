# Draw by Starlight — engineering notes

An iPhone app (iOS 26, Swift 6, SwiftUI) where you learn the constellations and the night sky by
drawing them, star to star, in tonight's real sky. Working name. This file is the map and the
rules.

## Map

- `Package.swift`: `StarlightCore` and `StarlightCoreTests`. The Xcode project builds
  StarlightCore from this package (local reference `..`); its iOS 26 / macOS 15 platforms are a
  floor.
- `Sources/StarlightCore`: the portable, dependency-free sky (builds on Linux too). `JulianDay`
  (a moment as days since 4713 BC; T since J2000.0), the time argument every sky computation
  starts from; `Time` (sidereal time, ΔT), `Coordinates` (`Equatorial`, `Horizontal`, `Place`),
  `Precession`, `Sun`, `Moon` (place, phase, the next new or full), `RiseAndSet` (`SkyObject`),
  `Catalogue` (`Star`, `Constellation`: figures and borders), `Projection` (a figure laid flat as
  the stargazer sees it). `Resources/`: the bundled sky, built by `tools/sky_data.py`, and
  `CREDITS.md`, its sources and licenses, for the Acknowledgements screen.
- `Tests/StarlightCoreTests` (Swift Testing), pinned to published values (below).
- `App/`: `DrawByStarlight.xcodeproj` (synchronized folders: adding files needs no project edit),
  `DrawByStarlight/` (`App/` the app, `Theme`, `Log` and `DemoMode`; `Tonight/` the home screen,
  empty until the sky lands; `Resources/` the catalogs, privacy manifest and assets),
  `DrawByStarlightTests` (Swift Testing), `DrawByStarlightUITests` (XCTest), `Config/Info.plist`
  (export compliance, the scene manifest; the rest is the target's `INFOPLIST_KEY_*` settings).
- `ci/` and `.github/workflows/ci.yml`: jobs `core` (Linux: StarlightCore tests, warnings, string
  catalog), `apple` (`iphone` on every push: Debug build, screenshots, unit and UI tests, Release
  check; or `compile`), `report` (`ci/report.py` writes `STATUS.md`). No IPA job and no SideStore
  source: the app stays out of SideStore until the owner says. The scripts came from
  `pbordjadze/paint-by-number`'s `ci/` by way of `pbordjadze/pigeon`, and keep their shape.
- `tools/`: `swift.sh` (SwiftPM in Docker), `strings_check.py` and `sky_data.py` (their docstrings
  are the manuals).
- `PRIVACY.md`: the privacy policy, word for word what the app does (below).
- Plans, briefs and the backlog are not committed here: they live in the private
  `painting-company` repository (this app is its row 128). A commit message says what changed and
  why, and cites a row by number; it quotes no one and names no one.

## The sky (hard rules)

- Real sky, real facts: every position, time and fact is computed or sourced, never made up.
  Positions come from a star catalogue at J2000, precessed to the date; the device computes
  sidereal time, altitude and azimuth, the Moon's place and phase, and rise and set times,
  offline, in StarlightCore.
- A computation's tests pin real values from a published source (an ephemeris, Meeus's
  *Astronomical Algorithms*), named in the test.
- Bundled data (stars, names, figures' lines, borders, stories) needs a license that allows
  bundling; reject on any doubt, and credit everything on the Acknowledgements screen.
- Angles in degrees, times as `JulianDay` or `Date`, in StarlightCore; the app converts for
  display.

## Privacy (hard rules)

No account, no server, no network, no analytics, no ads, no third-party code. Everything stays on
the device. No location permission: the place is a city the stargazer picks (asking for location
is the owner's decision). A change to what the app collects or asks for changes `PRIVACY.md`,
`Resources/PrivacyInfo.xcprivacy`, `ShipHygieneTests` and `ci/check_release.sh` together. A
required-reason API (UserDefaults, file timestamps, disk space, boot time) adds its category and
reason to the manifest, and to the list `ShipHygieneTests` pins (Debug-only code, like
`DemoMode`'s UserDefaults, doesn't ship and doesn't count).

## Working here (Linux, no Xcode)

| Task | Command |
| --- | --- |
| StarlightCore tests | `tools/swift.sh test` |
| String catalog check | `python3 tools/strings_check.py` |

- `App/` compiles only on CI: after editing an App Swift file, re-read it whole and check its
  imports (`MemberImportVisibility`), actor isolation at each boundary, API names and signatures
  against iOS 26 / Swift 6.2, and every call site of anything renamed.
- Compiler warnings fail CI (`ci/warnings.sh`, on the Linux and Xcode build logs; `main` has
  none): fix a new one, never silence it.
- Scratch output goes outside the repo. Keep a diff to what the task needs.

## App rules

- Deployment target iOS 26.0, iPhone (an iPad runs it as an iPhone app). Build with Xcode 26.6
  (CI). Swift 6 with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and approachable concurrency: app
  types are MainActor by default; mark pure helpers `nonisolated` and CPU-heavy async work
  `@concurrent`. StarlightCore is a separate module (nonisolated). The test targets use
  approachable concurrency but don't default to MainActor: suites that touch app types are
  `@MainActor`.
- `MemberImportVisibility` is enabled: every file that touches members of a type from another
  module imports that module itself (`import StarlightCore`, …); a file that logs through `Log`
  imports `os`.
- Night only: the sky is the canvas, so the app is always dark (`UIUserInterfaceStyle` Dark), and
  the Outside screen is dim red on true black.
- The look is Paint by Moonlight's design system (`Theme`, the asset catalog's colors): New York
  for titles, names and numerals, SF for the rest, Liquid Glass, antique gold only for stars,
  sparkles and the Moon, Nightshade under the one primary button, lavender for what's only a hint.
  System controls stay system controls, SF Symbols, Dynamic Type, VoiceOver labels and values,
  Reduce Motion.
- No lives, streaks, scores, counts or percentages anywhere: it stays a delight you can put down.
- Identity: the display name is the working name, Draw by Starlight. The product name, the icon,
  the bundle identifier's registration and the App Store listing are the owner's to decide; never
  change them unasked.
- A new screen or control goes through the owner's design review before it's built.
- Localization: every user-facing string of the app target lives in
  `Resources/Localizable.xcstrings` (English first), the Info.plist texts in
  `Resources/InfoPlist.xcstrings` (keyed by the plist key); StarlightCore stays English and returns
  values, not sentences. Three code forms, and nothing else: a SwiftUI literal with no
  interpolation (`Text("Done")`: the literal is the key); `String(localized: "key", defaultValue:
  "…\(x)…", comment: "…")` for an interpolation or a non-SwiftUI destination (dotted keys; the
  comment says where it shows and what the arguments are); `String(localized: "literal")` for a
  plain string. `Text(someString)` is verbatim, so build such strings with the second or third
  form first. Times, angles and numbers go through `.formatted(...)`, never concatenation. A new
  string needs its catalog entry written by hand (`"comment"`, `"extractionState": "manual"`; an
  explicit key also `localizations.en`): Xcode extracts nothing. `tools/strings_check.py` (CI)
  fails on drift.
- Demo scenarios: `-demo <name>` (`DemoMode`; scenarios listed on the views that render them). A
  screenshotted scenario is one `name@seconds` line of `ci/scenarios.txt` and calls
  `DemoMode.markReady()` once its content is on screen; `-long-text` in a name doubles every
  string. Demo code is `#if DEBUG`, and `ci/check_release.sh` fails if it shows up in the Release
  binary.
- Done means: a test for each new behaviour in the right target, a demo scenario for any new
  screen, catalog entries for its strings, VoiceOver, Dynamic Type and Reduce Motion for every new
  control, and this file's pointers kept current. No stubs or flags hiding unfinished work.

## CI feedback loop (no Xcode locally)

1. Before a push, look at the Actions runs of this repository and of `pbordjadze/paint-by-number`:
   the 5 macOS runners are shared by all the owner's apps. One branch at a time while
   paint-by-number's `main` runs.
2. Commit, push to a branch (`git push -u origin HEAD:<branch>`; CI runs on every branch). Compile
   first: `[compile]` in a branch commit's message runs only the Debug and Release builds, the
   Release check and the warnings gate on one runner, no simulator.
3. Run `CI_BRANCH=<branch> ci/fetch.sh <sha> <outdir>` in the background; it waits for the report
   CI publishes to the ref `refs/ci-shots/<branch>` (not fetched by a clone) and unpacks it:
   `STATUS.md` (job results, failed steps, test counts, failed tests with their first message,
   scenarios that never signalled readiness, crashes), logs, `core/`, and per job `errors.txt`,
   `shots/*.png`, `*-app.log`, `test-app.log`, test results and `attachments/`.
4. Read errors and screenshots, fix, repeat. Batch fixes: a newer push to the same branch cancels
   the older run.

**Branches.** `main` is the default branch. Work on `claude/<topic>` branches and merge into
`main` once CI is green and a reviewer that didn't write the change has read
`git diff origin/main...HEAD`; the merge commit lists what the review found and what was fixed.
Docs-only commits carry `[skip ci]`; a commit message holds CI's tags (`[skip ci]`,
`[compile]`) only to mean them.

## Conventions

- Swift 6 language mode, strict concurrency. Core types are `Sendable` value types.
- Comments explain *why*, sparingly. No dead code, no TODO litter.
