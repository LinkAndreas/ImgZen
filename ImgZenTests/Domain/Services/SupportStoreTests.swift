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

    @Test("One-time support says thank you and celebrates")
    func testOneTimePurchase() async throws {
        let store = SupportStore(service: PreviewSupportService())
        await store.load()
        let offer = try #require(store.oneTimeOffers.first)

        await store.purchase(offer)

        #expect(store.status == .thankYou)
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
}
