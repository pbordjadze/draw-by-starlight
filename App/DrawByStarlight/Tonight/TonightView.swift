import SwiftUI

/// The home screen: tonight's sky from where you are. Empty for now; the dome, tonight's
/// suggestion, the Moon and the place picker come with the sky (painting-company row 128).
///
/// Demo scenario: `tonight-empty`.
struct TonightView: View {
    var body: some View {
        NavigationStack {
            Theme.paper
                .ignoresSafeArea()
                .navigationTitle("Tonight")
        }
        #if DEBUG
        .onAppear { DemoMode.markReady() }
        #endif
    }
}

#Preview {
    TonightView()
}
