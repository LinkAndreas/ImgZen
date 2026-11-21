import Testing
@testable import ImgZen

struct WhatsNewTests {

    @Test("What's New shows after an update to people who already used the app")
    func testShowsAfterUpdate() {
        #expect(WhatsNew.shouldShow(lastSeen: nil, hasCompletedOnboarding: true))
        #expect(WhatsNew.shouldShow(lastSeen: "1.8", hasCompletedOnboarding: true))
    }

    @Test("What's New shows only once per release")
    func testShowsOnce() {
        #expect(!WhatsNew.shouldShow(lastSeen: WhatsNew.version, hasCompletedOnboarding: true))
    }

    @Test("New users get the onboarding instead of What's New")
    func testNotShownBeforeOnboarding() {
        #expect(!WhatsNew.shouldShow(lastSeen: nil, hasCompletedOnboarding: false))
    }

    @Test("What's New is about the newest release in the version history")
    func testVersionMatchesNewestRelease() throws {
        let newest = try #require(Release.history.first)
        #expect(newest.version.hasPrefix(WhatsNew.version + "."))
    }

    @Test("Every feature is listed once")
    func testFeaturesAreUnique() {
        #expect(!WhatsNew.features.isEmpty)
        #expect(Set(WhatsNew.features.map(\.id)).count == WhatsNew.features.count)
    }
}
