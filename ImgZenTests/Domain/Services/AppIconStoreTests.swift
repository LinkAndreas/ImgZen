import Testing
@testable import ImgZen

@MainActor
struct AppIconStoreTests {

    private struct Refused: Error {}

    @Test("Starts plain, like the launch screen, and shows the icon's colors once on screen")
    func testTheme() {
        let store = AppIconStore(alternateIconName: "AppIcon-Ember") { _ in }

        #expect(store.current == .ember)
        #expect(store.theme == nil)

        store.showTheme()
        #expect(store.theme == .ember)
    }

    @Test("Selecting an icon changes the app's icon, logo and colors")
    func testSelect() async throws {
        var requestedNames: [String?] = []
        let store = AppIconStore(alternateIconName: nil) { requestedNames.append($0) }

        try await store.select(.noir)
        try await store.select(.classic)

        #expect(requestedNames == ["AppIcon-Noir", nil])
        #expect(store.current == .classic)
        #expect(store.theme == .classic)
    }

    @Test("Selecting the current icon doesn't ask the system again")
    func testSelectCurrent() async throws {
        var requestCount = 0
        let store = AppIconStore(alternateIconName: "AppIcon-Dune") { _ in requestCount += 1 }

        try await store.select(.dune)

        #expect(requestCount == 0)
    }

    @Test("When the system refuses the icon, the app goes back to the previous one")
    func testSelectRefused() async {
        let store = AppIconStore(alternateIconName: "AppIcon-Matcha") { _ in throw Refused() }
        store.showTheme()

        await #expect(throws: Refused.self) {
            try await store.select(.glacier)
        }
        #expect(store.current == .matcha)
        #expect(store.theme == .matcha)
    }
}
