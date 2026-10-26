import SwiftUI

@main
struct DrawByStarlightApp: App {
    init() {
        Theme.styleNavigationTitles()
    }

    var body: some Scene {
        WindowGroup {
            TonightView()
        }
    }
}
