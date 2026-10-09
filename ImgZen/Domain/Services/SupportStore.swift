import Foundation
import Observation

/// Purchase state for the Support the Developer screen: the available offers,
/// what's in progress, the active subscription, and the last outcome to report.
///
/// No feature is ever locked; recurring support unlocks only the supporter app
/// icons, as a thank-you, and anyone who has supported is thanked on the screen.
/// Entitlements and past support are always read from the App Store.
@Observable
final class SupportStore {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        /// Offline, StoreKit unavailable, or no products configured.
        case unavailable
    }

    /// The latest outcome that needs a word on the Support screen. A completed purchase
    /// has none: the header thanks the supporter for good, and the screen celebrates it.
    enum Status: Equatable {
        case pending
        case restored
        case nothingToRestore
        case failed(SupportStoreError)
    }

    private(set) var oneTimeOffers: [SupportOffer] = []
    private(set) var subscriptionOffers: [SupportOffer] = []
    private(set) var loadState: LoadState = .idle
    private(set) var activeSubscription: ActiveSupportSubscription?
    /// Whether this Apple Account has ever given one-time support, which the screen thanks
    /// them for. It unlocks nothing: one-time support is consumable.
    private(set) var hasGivenOneTimeSupport = false
    private(set) var purchasingProductID: SupportProductID?
    private(set) var isRestoring = false
    private(set) var status: Status?
    /// Goes up with every completed purchase — one-time support or a new
    /// subscription, not renewals — so the screen can celebrate it.
    private(set) var celebrationCount = 0

    @ObservationIgnored private let service: SupportStoreService
    @ObservationIgnored private var transactionObserver: Task<Void, Never>?
    @ObservationIgnored private var subscriptionObserver: Task<Void, Never>?

    init(service: SupportStoreService) {
        self.service = service
    }

    var isBusy: Bool { purchasingProductID != nil || isRestoring }

    /// Whether recurring support is active, which unlocks the supporter app icons.
    var isSupporter: Bool { activeSubscription != nil }

    /// Whether to thank the user for their support: one-time or recurring.
    var hasSupported: Bool { isSupporter || hasGivenOneTimeSupport }

    /// Starts listening for transactions that complete outside the purchase flow.
    /// Call once at launch so approvals and renewals are finished promptly.
    func startObservingTransactions() {
        guard transactionObserver == nil else { return }
        transactionObserver = service.observeTransactions { [weak self] id in
            await self?.transactionCompleted(id)
        }
        // A cancellation or plan change creates no transaction, only a new subscription status.
        subscriptionObserver = service.observeSubscriptionChanges { [weak self] in
            await self?.refreshSubscription()
        }
    }

    /// Reads the subscription again, e.g. after it was cancelled or changed in the App Store's
    /// subscription management.
    func refreshSubscription() async {
        activeSubscription = await service.activeSubscription()
    }

    func load() async {
        guard loadState != .loading else { return }
        if loadState != .loaded { loadState = .loading }

        // Fetch everything first and apply it in one go, so the screen changes once
        // instead of reflowing when the subscription arrives after the offers.
        let offers: [SupportOffer]?
        do {
            offers = try await service.loadOffers()
        } catch {
            offers = nil
        }
        let subscription = await service.activeSubscription()
        let hasGivenOneTimeSupport = await service.hasGivenOneTimeSupport()

        activeSubscription = subscription
        self.hasGivenOneTimeSupport = hasGivenOneTimeSupport
        if let offers {
            oneTimeOffers = offers.filter { $0.id.kind == .oneTime }
            subscriptionOffers = offers.filter { $0.id.kind == .subscription }
        }
        loadState = offers?.isEmpty == false ? .loaded : .unavailable
    }

    func purchase(_ offer: SupportOffer) async {
        guard !isBusy else { return }
        purchasingProductID = offer.id
        status = nil
        defer { purchasingProductID = nil }

        do {
            switch try await service.purchase(offer.id) {
            case .purchased:
                await purchaseCompleted(offer.id)
            case .pending:
                status = .pending
            case .cancelled:
                break
            }
        } catch let error as SupportStoreError {
            status = .failed(error)
        } catch {
            status = .failed(.purchaseFailed)
        }
    }

    func restorePurchases() async {
        guard !isBusy else { return }
        isRestoring = true
        status = nil
        defer { isRestoring = false }

        do {
            try await service.restorePurchases()
            activeSubscription = await service.activeSubscription()
            hasGivenOneTimeSupport = await service.hasGivenOneTimeSupport()
            status = activeSubscription == nil ? .nothingToRestore : .restored
        } catch {
            status = .failed(.restoreFailed)
        }
    }

    func dismissStatus() {
        status = nil
    }

    // MARK: Private

    private func purchaseCompleted(_ id: SupportProductID) async {
        celebrationCount += 1
        switch id.kind {
        case .oneTime:
            hasGivenOneTimeSupport = true
        case .subscription:
            // The subscription section shows its own thank-you.
            activeSubscription = await service.activeSubscription()
        }
    }

    private func transactionCompleted(_ id: SupportProductID) async {
        // A purchase that was waiting for approval went through (renewals don't celebrate).
        if status == .pending {
            status = nil
            celebrationCount += 1
        }
        // Also one-time support given on another device, or approved later.
        if id.kind == .oneTime {
            hasGivenOneTimeSupport = true
        }
        activeSubscription = await service.activeSubscription()
    }
}
