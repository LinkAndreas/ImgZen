import SwiftUI

/// The active subscription on its own, for when the offers that would show it can't load.
struct ActiveSubscriptionRow: View {
    let subscription: ActiveSupportSubscription

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "support.recurringSupportIsActive"))
                if let renewalText = subscription.renewalText {
                    Text(verbatim: renewalText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: "heart.fill")
                .foregroundStyle(.pink)
        }
    }
}

extension ActiveSupportSubscription {
    /// When the subscription renews, or ends if it won't or is switching to another plan.
    var renewalText: String? {
        guard let date = expirationDate?.formatted(date: .abbreviated, time: .omitted) else { return nil }
        let renews = willAutoRenew && nextProductID == nil
        return String(format: String(localized: renews ? "support.renewsOn" : "support.endsOn"), date)
    }

    /// When the plan it's switching to starts.
    var nextPlanText: String? {
        guard nextProductID != nil, willAutoRenew,
              let date = expirationDate?.formatted(date: .abbreviated, time: .omitted) else { return nil }
        return String(format: String(localized: "support.startsOn"), date)
    }
}

#if DEBUG
#Preview {
    List {
        ActiveSubscriptionRow(subscription: ActiveSupportSubscription(productID: .yearly, expirationDate: .now.addingTimeInterval(200 * 86_400), willAutoRenew: true))
    }
}
#endif
