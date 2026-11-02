import SwiftUI

@main
struct DrawByStarlightApp: App {
    init() {
        Theme.styleNavigationTitles()
    }

    var body: some Scene {
        WindowGroup {
            TonightView()
                // Controls and links in parchment, never system blue; gold stays the stars'.
                .tint(Theme.ink)
        }
    }
}
