import Foundation

extension BillingPeriod {
    /// In the app's language — StoreKit's own wording follows the App Store
    /// storefront, which can differ from the language the app runs in.
    var billingText: String {
        switch self {
        case .day: String(localized: "support.billedDaily")
        case .week: String(localized: "support.billedWeekly")
        case .month: String(localized: "support.billedMonthly")
        case .year: String(localized: "support.billedYearly")
        }
    }
}
