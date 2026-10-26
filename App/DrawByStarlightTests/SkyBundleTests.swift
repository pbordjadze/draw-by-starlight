import Foundation
import StarlightCore
import Testing

/// StarlightCore's sky ships inside the app: its resource bundle is copied in and reads on iOS.
struct SkyBundleTests {
    @Test func theCatalogueReadsInTheApp() {
        let catalogue = Catalogue.bundled
        #expect(catalogue.stars.count == 9096)
        #expect(catalogue.constellations.count == 88)
        #expect(catalogue.stars[2061]?.name == "Betelgeuse")
    }
}
