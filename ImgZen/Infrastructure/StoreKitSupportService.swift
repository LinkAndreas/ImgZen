import Foundation
import StoreKit

/// `SupportStoreService` backed by StoreKit 2. The only place in the app that
/// imports StoreKit's purchasing API.
final class StoreKitSupportService: SupportStoreService {
    private var products: [SupportProductID: Product] = [:]
    /// The last renewal state read for each plan, for when it can't be read again, e.g. offline.
    private var renewalStates: [SupportProductID: RenewalState] = [:]

    private struct RenewalState {
        var willAutoRenew: Bool
        var nextProductID: SupportProductID?
    }

    func loadOffers() async throws -> [SupportOffer] {
        let storeProducts: [Product]
        do {
            storeProducts = try await Product.products(for: SupportProductID.allCases.map(\.rawValue))
        } catch {
            throw SupportStoreError.storeUnavailable
        }

        var offers: [SupportOffer] = []
        for product in storeProducts {
            guard let id = SupportProductID(rawValue: product.id) else { continue }
            products[id] = product
            offers.append(SupportOffer(
                id: id,
                displayName: product.displayName,
                description: product.description,
                displayPrice: product.displayPrice,
                billingPeriod: product.subscription.map { BillingPeriod($0.subscriptionPeriod.unit) }
            ))
        }

        // Keep the catalog's order rather than the App Store's.
        let order = SupportProductID.allCases
        return offers.sorted { order.firstIndex(of: $0.id)! < order.firstIndex(of: $1.id)! }
    }

    func purchase(_ id: SupportProductID) async throws -> PurchaseOutcome {
        guard let product = products[id] else { throw SupportStoreError.productUnavailable }

        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            throw SupportStoreError.purchaseFailed
        }

        switch result {
        case let .success(verification):
            let transaction = try verified(verification)
            await transaction.finish()
            return .purchased
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    func activeSubscription() async -> ActiveSupportSubscription? {
        // `currentEntitlements` only contains subscriptions that are still active.
        for await result in Transaction.currentEntitlements {
            // After an upgrade, the plan it replaced stays among the entitlements, marked upgraded.
            guard case let .verified(transaction) = result,
                  transaction.productType == .autoRenewable,
                  transaction.revocationDate == nil,
                  !transaction.isUpgraded,
                  let id = SupportProductID(rawValue: transaction.productID)
            else { continue }

            let renewal = await renewalState(of: transaction, id: id)
            return ActiveSupportSubscription(
                productID: id,
                expirationDate: transaction.expirationDate,
                willAutoRenew: renewal.willAutoRenew,
                nextProductID: renewal.nextProductID
            )
        }
        return nil
    }

    func hasSubscriptionEnded() async -> Bool {
        guard let statuses = await groupStatuses() else { return false }
        // A renewal that's late or failing to bill isn't the end yet; only expired and refunded are.
        return statuses.allSatisfy { $0.state == .expired || $0.state == .revoked }
    }

    func hasBillingIssue() async -> Bool {
        guard let statuses = await groupStatuses() else { return false }
        return statuses.contains { $0.state == .inBillingRetryPeriod || $0.state == .inGracePeriod }
    }

    func hasGivenOneTimeSupport() async -> Bool {
        // One-time support is consumable, and finished consumables are only in the history
        // because Info.plist sets SKIncludeConsumableInAppPurchaseHistory.
        for await result in Transaction.all {
            guard case let .verified(transaction) = result,
                  transaction.revocationDate == nil,
                  let id = SupportProductID(rawValue: transaction.productID),
                  id.kind == .oneTime
            else { continue }
            return true
        }
        return false
    }

    func restorePurchases() async throws {
        do {
            try await AppStore.sync()
        } catch {
            throw SupportStoreError.restoreFailed
        }
    }

    func observeSubscriptionChanges(
        onChange: @escaping @MainActor () async -> Void
    ) -> Task<Void, Never> {
        Task {
            for await _ in Product.SubscriptionInfo.Status.updates {
                await onChange()
            }
        }
    }

    func observeTransactions(
        onTransaction: @escaping @MainActor (SupportProductID) async -> Void
    ) -> Task<Void, Never> {
        Task {
            // Transactions left unfinished last time, e.g. the app quit mid-purchase.
            for await result in Transaction.unfinished {
                _ = await finishIfVerified(result)
            }
            for await result in Transaction.updates {
                if let id = await finishIfVerified(result) {
                    await onTransaction(id)
                }
            }
        }
    }

    // MARK: Private

    /// Finishes a verified transaction and returns its product. Unverified
    /// transactions are left unfinished and ignored.
    private func finishIfVerified(_ result: VerificationResult<Transaction>) async -> SupportProductID? {
        guard case let .verified(transaction) = result else { return nil }
        await transaction.finish()
        return SupportProductID(rawValue: transaction.productID)
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case let .verified(value): value
        case .unverified: throw SupportStoreError.verificationFailed
        }
    }

    /// The statuses of the support subscription group, or `nil` when they can't be read.
    private func groupStatuses() async -> [Product.SubscriptionInfo.Status]? {
        // Both plans share a group, so either one's statuses cover the whole group.
        let product: Product?
        if let cached = products[.monthly] ?? products[.yearly] {
            product = cached
        } else {
            product = try? await Product.products(for: [SupportProductID.monthly.rawValue]).first
        }
        guard let subscription = product?.subscription else { return nil }
        return try? await subscription.status
    }

    /// Whether the subscription renews, and into which plan when it's switching to another one.
    /// When it can't be read, the last state read stands rather than assuming it renews.
    private func renewalState(of transaction: Transaction, id: SupportProductID) async -> RenewalState {
        // The transaction's own status needs no product from the App Store, so it's read even offline.
        if let status = await transaction.subscriptionStatus,
           case let .verified(renewalInfo) = status.renewalInfo {
            // A switch that's been cancelled too has nothing next: the subscription just ends.
            let next = renewalInfo.willAutoRenew
                ? renewalInfo.autoRenewPreference.flatMap(SupportProductID.init(rawValue:))
                : nil
            let state = RenewalState(willAutoRenew: renewalInfo.willAutoRenew, nextProductID: next == id ? nil : next)
            renewalStates[id] = state
            return state
        }
        return renewalStates[id] ?? RenewalState(willAutoRenew: true, nextProductID: nil)
    }
}

private extension BillingPeriod {
    init(_ unit: Product.SubscriptionPeriod.Unit) {
        self = switch unit {
        case .day: .day
        case .week: .week
        case .year: .year
        default: .month
        }
    }
}
