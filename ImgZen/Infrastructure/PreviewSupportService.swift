// Previews and tests only; not part of the shipping app.
#if DEBUG
import Foundation

/// An in-memory `SupportStoreService` for previews and tests: configurable
/// offers, purchase outcome, and failures, with no App Store involved.
final class PreviewSupportService: SupportStoreService {
    var offers: [SupportOffer]
    var subscription: ActiveSupportSubscription?
    var hasTipped = false
    var purchaseOutcome: PurchaseOutcome = .purchased
    var failsToLoad = false
    /// Whether the App Store would confirm the subscription has ended; `nil` follows `subscription`.
    var subscriptionHasEnded: Bool?
    var billingIssue = false

    init(
        offers: [SupportOffer] = PreviewSupportService.sampleOffers,
        subscription: ActiveSupportSubscription? = nil,
        hasTipped: Bool = false
    ) {
        self.offers = offers
        self.subscription = subscription
        self.hasTipped = hasTipped
    }

    func loadOffers() async throws -> [SupportOffer] {
        if failsToLoad { throw SupportStoreError.storeUnavailable }
        return offers
    }

    func purchase(_ id: SupportProductID) async throws -> PurchaseOutcome {
        if purchaseOutcome == .purchased, id.kind == .oneTime {
            hasTipped = true
        }
        if purchaseOutcome == .purchased, id.kind == .subscription {
            if let current = subscription, current.productID == .yearly, id == .monthly {
                // A switch to the lower plan, as StoreKit does it: from the end of the current period.
                subscription = ActiveSupportSubscription(
                    productID: current.productID,
                    expirationDate: current.expirationDate,
                    willAutoRenew: current.willAutoRenew,
                    nextProductID: .monthly
                )
            } else {
                subscription = ActiveSupportSubscription(
                    productID: id,
                    expirationDate: Calendar.current.date(byAdding: id == .yearly ? .year : .month, value: 1, to: .now),
                    willAutoRenew: true
                )
            }
        }
        return purchaseOutcome
    }

    func activeSubscription() async -> ActiveSupportSubscription? {
        subscription
    }

    func hasSubscriptionEnded() async -> Bool {
        subscriptionHasEnded ?? (subscription == nil)
    }

    func hasBillingIssue() async -> Bool {
        billingIssue
    }

    func hasGivenOneTimeSupport() async -> Bool {
        hasTipped
    }

    func restorePurchases() async throws {}

    func observeTransactions(
        onTransaction: @escaping @MainActor (SupportProductID) async -> Void
    ) -> Task<Void, Never> {
        Task {}
    }

    func observeSubscriptionChanges(
        onChange: @escaping @MainActor () async -> Void
    ) -> Task<Void, Never> {
        Task {}
    }

    static let sampleOffers: [SupportOffer] = [
        SupportOffer(id: .small, displayName: "Small Support", description: "Buy the developer a coffee.", displayPrice: "€2.99", billingPeriod: nil),
        SupportOffer(id: .medium, displayName: "Support", description: "Help keep ImgZen growing.", displayPrice: "€5.99", billingPeriod: nil),
        SupportOffer(id: .generous, displayName: "Generous Support", description: "A big thank you.", displayPrice: "€9.99", billingPeriod: nil),
        SupportOffer(id: .monthly, displayName: "Monthly Support", description: "Unlocks the supporter app icons.", displayPrice: "€1.99", billingPeriod: .month),
        SupportOffer(id: .yearly, displayName: "Yearly Support", description: "Unlocks the supporter app icons.", displayPrice: "€14.99", billingPeriod: .year),
    ]
}
#endif
