import SwiftUI

struct ActiveSubscriptionRow: View {
    let subscription: ActiveSupportSubscription

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "support.thankYouForSupporting"))
                if let date = subscription.expirationDate?.formatted(date: .abbreviated, time: .omitted) {
                    Text(String(format: String(localized: subscription.willAutoRenew ? "support.renewsOn" : "support.endsOn"), date))
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

#if DEBUG
#Preview {
    List {
        ActiveSubscriptionRow(subscription: ActiveSupportSubscription(productID: .yearly, expirationDate: .now.addingTimeInterval(200 * 86_400), willAutoRenew: true))
    }
}
#endif
