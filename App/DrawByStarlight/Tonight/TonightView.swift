import StarlightCore
import SwiftUI

/// The home screen: tonight's whole sky (`SkyDomeView`), each figure there to be touched and
/// drawn, the ones not up yet waiting under the horizon.
///
/// Demo scenarios: `constellations` (the sky, Cassiopeia drawn and Cygnus begun); `draw-…` opens
/// a constellation (`DrawingView`).
struct TonightView: View {
    @State private var sky = Sky.tonight()
    @State private var path: [String] = []
    @Environment(\.scenePhase) private var scenePhase
    private let drawn = Self.store()

    /// The stargazer's drawings; a demo scenario (and so a screenshot or a UI test) gets a store of
    /// its own in memory, so it neither reads nor leaves anything on the device.
    private static func store() -> DrawnFigures {
        #if DEBUG
        if DemoMode.isActive { return DrawnFigures(file: nil) }
        #endif
        return DrawnFigures.shared
    }

    var body: some View {
        NavigationStack(path: $path) {
            SkyDomeView(sky: sky, drawn: drawn, showing: path.isEmpty) { id in
                path.append(id)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("Tonight")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                if let constellation = sky.constellation(id) {
                    DrawingView(constellation: constellation, sky: sky, drawn: drawn)
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Back after a while (the next evening, say): tonight's sky again.
            if phase == .active, Date.now.timeIntervalSince(sky.now) > 1800, path.isEmpty {
                sky = Sky.tonight()
            }
        }
        #if DEBUG
        .onAppear {
            guard let scenario = DemoMode.scenario else { return }
            if scenario.hasPrefix("draw-"), let constellation = demoConstellation(scenario) {
                path = [constellation.id]
            } else {
                // Something drawn, to show it inked in: Cassiopeia whole, Cygnus begun.
                drawn.record("Cas", at: DemoMode.fixedNow)
                drawn.keep([[7949, 7796], [7796, 7615]], of: "Cyg")
                // Ready once the sky has wheeled into place (`SkyDomeView`).
            }
        }
        #endif
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
