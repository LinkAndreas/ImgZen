import Foundation

/// A support product as the App Store describes it: localized name and price.
struct SupportOffer: Identifiable, Equatable, Sendable {
    let id: SupportProductID
    let displayName: String
    let description: String
    let displayPrice: String
    /// How often a subscription renews; `nil` for one-time support. A value rather
    /// than StoreKit's text, so the app words it in its own language.
    let billingPeriod: BillingPeriod?
}

/// How often a subscription renews.
enum BillingPeriod: Equatable, Sendable {
    case day, week, month, year
}

/// The user's current recurring support, derived from verified App Store
/// entitlements — never stored by the app itself.
struct ActiveSupportSubscription: Equatable, Sendable {
    let productID: SupportProductID
    let expirationDate: Date?
    let willAutoRenew: Bool
    /// The plan it renews into when that's a different one: a switch to a lower plan, such as
    /// yearly to monthly, takes effect only when the current period ends.
    var nextProductID: SupportProductID? = nil
}

enum PurchaseOutcome: Equatable, Sendable {
    /// Verified and finished.
    case purchased
    /// Waiting for approval, e.g. Ask to Buy; completes later through the
    /// transaction listener.
    case pending
    case cancelled
}

enum SupportStoreError: Error, Equatable, Sendable {
    /// The App Store couldn't be reached, or returned no products.
    case storeUnavailable
    /// The product wasn't loaded when a purchase was attempted.
    case productUnavailable
    /// The App Store's signature on the transaction didn't verify.
    case verificationFailed
    case purchaseFailed
    case restoreFailed
}

/// Everything the Support screen needs from the App Store. `StoreKitSupportService`
/// talks to StoreKit 2; `PreviewSupportService` stands in for previews and tests.
protocol SupportStoreService: AnyObject {
    /// The products available in the current storefront, in catalog order.
    func loadOffers() async throws -> [SupportOffer]
    func purchase(_ id: SupportProductID) async throws -> PurchaseOutcome
    func activeSubscription() async -> ActiveSupportSubscription?
    /// Whether the App Store confirms that recurring support has ended: expired, refunded, or never
    /// started. `false` when it can't tell, such as offline, so nothing is taken away by mistake.
    func hasSubscriptionEnded() async -> Bool
    /// Whether a renewal couldn't be charged and the App Store is still trying: the subscription
    /// is in its billing retry or grace period until the payment method is updated.
    func hasBillingIssue() async -> Bool
    /// Whether this Apple Account has ever given one-time support, on any device.
    func hasGivenOneTimeSupport() async -> Bool
    func restorePurchases() async throws
    /// Finishes transactions that complete outside a purchase call — Ask to Buy
    /// approvals, renewals, purchases on other devices — calling
    /// `onTransaction` for each. Runs until the returned task is cancelled.
    func observeTransactions(
        onTransaction: @escaping @MainActor (SupportProductID) async -> Void
    ) -> Task<Void, Never>
    /// Calls `onChange` whenever a subscription's status or renewal changes, such as when it's
    /// cancelled, which creates no transaction. Runs until the returned task is cancelled.
    func observeSubscriptionChanges(
        onChange: @escaping @MainActor () async -> Void
    ) -> Task<Void, Never>
}
