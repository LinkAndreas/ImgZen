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
    /// When the subscription renews, or ends if it won't.
    var renewalText: String? {
        guard let date = expirationDate?.formatted(date: .abbreviated, time: .omitted) else { return nil }
        return String(format: String(localized: willAutoRenew ? "support.renewsOn" : "support.endsOn"), date)
    }
}

#if DEBUG
#Preview {
    List {
        ActiveSubscriptionRow(subscription: ActiveSupportSubscription(productID: .yearly, expirationDate: .now.addingTimeInterval(200 * 86_400), willAutoRenew: true))
    }
}
#endif
