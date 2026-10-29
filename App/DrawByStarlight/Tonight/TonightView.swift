import StarlightCore
import SwiftUI

/// The home screen. Until tonight's sky lands here (painting-company row 128, slice 4) it is a
/// plain list of the constellations that can be drawn, each with where it stands tonight, and a
/// sparkle on the ones drawn.
///
/// Demo scenarios: `constellations` (the list); `draw-…` opens a constellation (`DrawingView`).
struct TonightView: View {
    @State private var sky = Sky.tonight()
    @State private var path: [String] = []
    private let drawn = DrawnFigures.shared

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    ForEach(standings, id: \.constellation.id) { standing in
                        NavigationLink(value: standing.constellation.id) {
                            row(standing)
                        }
                        .listRowBackground(Theme.surface)
                    }
                } header: {
                    Text("Draw")
                } footer: {
                    Text("Each is turned as it sits in your sky tonight.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("Tonight")
            .navigationDestination(for: String.self) { id in
                if let constellation = sky.constellation(id) {
                    DrawingView(constellation: constellation, sky: sky, drawn: drawn)
                }
            }
        }
        #if DEBUG
        .onAppear {
            guard let scenario = DemoMode.scenario else { return }
            if scenario.hasPrefix("draw-"), let constellation = demoConstellation(scenario) {
                path = [constellation.id]
            } else {
                DemoMode.markReady()
            }
        }
        #endif
    }

    private func row(_ standing: FigureScene) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: standing.constellation.name)
                    .font(.display(.headline, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(verbatim: SkyWords.listing(standing, place: sky.place, time: sky.time))
                    .font(.subheadline)
                    .foregroundStyle(Theme.lavender)
            }
            Spacer(minLength: 0)
            if drawn.isDrawn(standing.constellation.id) {
                SparkleShape()
                    .fill(Theme.gold)
                    .frame(width: 14, height: 14)
                    .accessibilityLabel("Drawn")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    /// Where each constellation stands tonight: the ones up now first, highest first; then the
    /// ones rising later, soonest first; then the ones that never rise from here.
    private var standings: [FigureScene] {
        sky.drawable.map { sky.scene($0, backdrop: false) }.sorted { a, b in
            switch (a.timing, b.timing) {
            case (.now, .now): (a.center?.altitude ?? 0) > (b.center?.altitude ?? 0)
            case (.now, _): true
            case (_, .now): false
            case (.later(let x), .later(let y)), (.later(let x), .beforeDawn(let y)),
                 (.beforeDawn(let x), .later(let y)), (.beforeDawn(let x), .beforeDawn(let y)): x < y
            case (.later, _), (.beforeDawn, _): true
            case (_, .later), (_, .beforeDawn): false
            default: a.constellation.name < b.constellation.name
            }
        }
    }

    #if DEBUG
    /// `draw-ursa-major-hint` → Ursa Major.
    private func demoConstellation(_ scenario: String) -> Constellation? {
        let slug = scenario.dropFirst("draw-".count)
        return sky.drawable.first { constellation in
            let name = constellation.name.lowercased().replacingOccurrences(of: " ", with: "-")
            return slug == name[...] || slug.hasPrefix(name + "-")
        }
    }
    #endif
}

#Preview {
    TonightView()
}
