import Foundation
import Testing
@testable import ImgZen

@MainActor
struct SupportStoreTests {

    @Test("Loading splits the offers into one-time and recurring support, in catalog order")
    func testLoadSplitsOffers() async {
        let store = SupportStore(service: PreviewSupportService())

        await store.load()

        #expect(store.loadState == .loaded)
        #expect(store.oneTimeOffers.map(\.id) == [.small, .medium, .generous])
        #expect(store.subscriptionOffers.map(\.id) == [.monthly, .yearly])
    }

    @Test("Loading reports the store as unavailable when the App Store can't be reached")
    func testLoadFailure() async {
        let service = PreviewSupportService()
        service.failsToLoad = true
        let store = SupportStore(service: service)

        await store.load()

        #expect(store.loadState == .unavailable)
        #expect(store.oneTimeOffers.isEmpty)
    }

    @Test("Loading reports the store as unavailable when no products are configured")
    func testLoadWithoutProducts() async {
        let store = SupportStore(service: PreviewSupportService(offers: []))

        await store.load()

        #expect(store.loadState == .unavailable)
    }

    @Test("One-time support celebrates, with nothing left to report")
    func testOneTimePurchase() async throws {
        let store = SupportStore(service: PreviewSupportService())
        await store.load()
        let offer = try #require(store.oneTimeOffers.first)

        await store.purchase(offer)

        #expect(store.status == nil)
        #expect(store.celebrationCount == 1)
        #expect(store.purchasingProductID == nil)
    }

    @Test("A new subscription becomes the active subscription and celebrates")
    func testSubscriptionPurchase() async throws {
        let store = SupportStore(service: PreviewSupportService())
        await store.load()
        let offer = try #require(store.subscriptionOffers.first { $0.id == .yearly })

        await store.purchase(offer)

        #expect(store.activeSubscription?.productID == .yearly)
        #expect(store.celebrationCount == 1)
        #expect(store.status == nil)
    }

    @Test("Switching from yearly to monthly keeps yearly active and schedules monthly for when it ends")
    func testSwitchToLowerPlan() async throws {
        let store = SupportStore(service: PreviewSupportService())
        await store.load()

        await store.purchase(try #require(store.subscriptionOffers.first { $0.id == .yearly }))
        await store.purchase(try #require(store.subscriptionOffers.first { $0.id == .monthly }))

        #expect(store.activeSubscription?.productID == .yearly)
        #expect(store.activeSubscription?.nextProductID == .monthly)
        #expect(store.activeSubscription?.nextPlanText != nil)
    }

    @Test("A purchase waiting for approval says so, without celebrating yet")
    func testPendingPurchase() async throws {
        let service = PreviewSupportService()
        service.purchaseOutcome = .pending
        let store = SupportStore(service: service)
        await store.load()
        let offer = try #require(store.oneTimeOffers.first)

        await store.purchase(offer)

        #expect(store.status == .pending)
        #expect(store.celebrationCount == 0)
    }

    @Test("A cancelled purchase leaves no message")
    func testCancelledPurchase() async throws {
        let service = PreviewSupportService()
        service.purchaseOutcome = .cancelled
        let store = SupportStore(service: service)
        await store.load()
        let offer = try #require(store.oneTimeOffers.first)

        await store.purchase(offer)

        #expect(store.status == nil)
        #expect(store.celebrationCount == 0)
    }

    @Test("Restoring without a subscription says there was nothing to restore")
    func testRestoreWithoutPurchases() async {
        let store = SupportStore(service: PreviewSupportService())

        await store.restorePurchases()

        #expect(store.status == .nothingToRestore)
        #expect(!store.isRestoring)
    }

    @Test("Restoring an active subscription reports it as restored")
    func testRestoreSubscription() async {
        let subscription = ActiveSupportSubscription(productID: .monthly, expirationDate: nil, willAutoRenew: true)
        let store = SupportStore(service: PreviewSupportService(subscription: subscription))

        await store.restorePurchases()

        #expect(store.status == .restored)
        #expect(store.activeSubscription == subscription)
    }

    @Test("Only a subscription unlocks the supporter icons, not one-time support")
    func testSupporterIconsUnlock() async throws {
        let store = SupportStore(service: PreviewSupportService())
        await store.load()
        #expect(!store.isSupporter)

        await store.purchase(try #require(store.oneTimeOffers.first))
        #expect(!store.isSupporter)

        await store.purchase(try #require(store.subscriptionOffers.first))
        #expect(store.isSupporter)
    }

    @Test("One-time support is remembered and thanked for, without unlocking the icons")
    func testOneTimeSupportIsThanked() async throws {
        let store = SupportStore(service: PreviewSupportService())
        await store.load()
        #expect(!store.hasSupported)

        await store.purchase(try #require(store.oneTimeOffers.first))

        #expect(store.hasGivenOneTimeSupport)
        #expect(store.hasSupported)
        #expect(!store.isSupporter)
    }

    @Test("One-time support given before, or on another device, is thanked for after loading")
    func testPastOneTimeSupport() async {
        let store = SupportStore(service: PreviewSupportService(hasTipped: true))

        await store.load()

        #expect(store.hasGivenOneTimeSupport)
        #expect(store.hasSupported)
    }

    @Test("A subscriber is thanked for their support")
    func testSubscriberIsThanked() async {
        let subscription = ActiveSupportSubscription(productID: .monthly, expirationDate: nil, willAutoRenew: true)
        let store = SupportStore(service: PreviewSupportService(subscription: subscription))

        await store.load()

        #expect(!store.hasGivenOneTimeSupport)
        #expect(store.hasSupported)
    }
}

@MainActor
struct SupporterIconTests {

    @Test("Each icon maps to its alternate icon set and back, the classic icon to the primary one")
    func testAlternateIconNames() {
        #expect(SupporterIcon.classic.alternateIconName == nil)
        #expect(SupporterIcon.amethyst.alternateIconName == "AppIcon-Amethyst")
        for icon in SupporterIcon.allCases {
            #expect(SupporterIcon(alternateIconName: icon.alternateIconName) == icon)
        }
        #expect(SupporterIcon(alternateIconName: "Unknown") == .classic)
    }
}
