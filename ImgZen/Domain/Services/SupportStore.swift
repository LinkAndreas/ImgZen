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
    /// Whether a renewal couldn't be charged and the App Store is still trying. Recurring support
    /// is paused meanwhile — the subscription isn't active — until the payment method is updated.
    private(set) var hasBillingIssue = false
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
    @ObservationIgnored private var expiryCheck: Task<Void, Never>?
    /// The purchase waiting for approval, e.g. Ask to Buy.
    @ObservationIgnored private var pendingProductID: SupportProductID?
    /// Counts reads of the subscription, so one that finishes late can't overwrite a newer one.
    @ObservationIgnored private var subscriptionReads = 0

    init(service: SupportStoreService) {
        self.service = service
    }

    var isBusy: Bool { purchasingProductID != nil || isRestoring }

    /// Whether recurring support is active, which unlocks the supporter app icons.
    var isSupporter: Bool { activeSubscription != nil }

    /// Whether to thank the user for their support: one-time or recurring.
    var hasSupported: Bool { isSupporter || hasGivenOneTimeSupport }

    /// Starts listening for transactions that complete outside the purchase flow, and for changes
    /// to the subscription. Call once at launch so approvals and renewals are finished promptly.
    func startObservingTransactions() {
        guard transactionObserver == nil else { return }
        // Read at launch, not only on the Support screen: the supporter icons depend on it.
        Task { await refreshSubscription() }
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
        let read = beginSubscriptionRead()
        let subscription = await service.activeSubscription()
        let hasBillingIssue = await service.hasBillingIssue()
        apply(subscription, hasBillingIssue: hasBillingIssue, read: read)
    }

    /// Whether recurring support has ended for sure, so the supporter icon should go: no active
    /// subscription, and the App Store confirms it expired or was refunded. A renewal that's late
    /// or still being billed doesn't count, nor does being offline.
    func hasRecurringSupportEnded() async -> Bool {
        await refreshSubscription()
        guard activeSubscription == nil else { return false }
        return await service.hasSubscriptionEnded()
    }

    func load() async {
        guard loadState != .loading else { return }
        if loadState != .loaded { loadState = .loading }
        // Each visit starts afresh. A purchase waiting for approval still completes and is celebrated,
        // but its note doesn't linger: a declined request is never reported.
        status = nil

        // Fetch everything first and apply it in one go, so the screen changes once
        // instead of reflowing when the subscription arrives after the offers.
        let offers: [SupportOffer]?
        do {
            offers = try await service.loadOffers()
        } catch {
            offers = nil
        }
        let read = beginSubscriptionRead()
        let subscription = await service.activeSubscription()
        let hasBillingIssue = await service.hasBillingIssue()
        let hasGivenOneTimeSupport = await service.hasGivenOneTimeSupport()

        apply(subscription, hasBillingIssue: hasBillingIssue, read: read)
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
                pendingProductID = offer.id
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
            await refreshSubscription()
            hasGivenOneTimeSupport = await service.hasGivenOneTimeSupport()
            status = hasSupported ? .restored : .nothingToRestore
        } catch {
            status = .failed(.restoreFailed)
        }
    }

    func dismissStatus() {
        status = nil
    }

    // MARK: Private

    private func purchaseCompleted(_ id: SupportProductID) async {
        switch id.kind {
        case .oneTime:
            hasGivenOneTimeSupport = true
            celebrationCount += 1
        case .subscription:
            let previous = activeSubscription?.productID
            // The subscription section shows its own thank-you.
            await refreshSubscription()
            // A switch to a lower plan only takes effect at renewal: nothing new to celebrate yet.
            if previous == nil || activeSubscription?.productID != previous {
                celebrationCount += 1
            }
        }
    }

    private func transactionCompleted(_ id: SupportProductID) async {
        // The purchase that was waiting for approval went through (renewals don't celebrate).
        if id == pendingProductID {
            pendingProductID = nil
            if status == .pending { status = nil }
            celebrationCount += 1
        }
        // Also one-time support given on another device, approved later, or refunded,
        // so it's read again rather than assumed.
        if id.kind == .oneTime {
            hasGivenOneTimeSupport = await service.hasGivenOneTimeSupport()
        }
        await refreshSubscription()
    }

    private func beginSubscriptionRead() -> Int {
        subscriptionReads += 1
        return subscriptionReads
    }

    /// Applies a read of the subscription unless a newer one has started since — reads triggered
    /// close together (the management sheet closing, a status update, coming back to the app)
    /// can finish out of order.
    private func apply(_ subscription: ActiveSupportSubscription?, hasBillingIssue: Bool, read: Int) {
        guard read == subscriptionReads else { return }
        activeSubscription = subscription
        self.hasBillingIssue = hasBillingIssue
        scheduleExpiryCheck()
    }

    /// Reads the subscription again just after it runs out, as nothing else reports it while the
    /// app stays open; a renewal arrives as a transaction.
    private func scheduleExpiryCheck() {
        expiryCheck?.cancel()
        guard let expiration = activeSubscription?.expirationDate else { return }
        expiryCheck = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(0, expiration.timeIntervalSinceNow) + 2))
            guard !Task.isCancelled else { return }
            await self?.refreshSubscription()
        }
    }
}
