import StoreKit
import SwiftUI

/// Support the Developer: a quiet, optional way to pay for ImgZen's development.
/// Nothing here unlocks features — the app stays fully free.
struct SupportView: View {
    @Environment(SupportStore.self) private var store
    @State private var isManagingSubscription = false

    var body: some View {
        Form {
            Section {
                SupportHeader()
            }
            .listRowBackground(Color.clear)

            if let subscription = store.activeSubscription {
                Section {
                    ActiveSubscriptionRow(subscription: subscription)
                    Button(String(localized: "support.manageSubscription")) {
                        isManagingSubscription = true
                    }
                }
            }

            if let status = store.status {
                Section {
                    SupportStatusRow(status: status)
                }
            }

            SupportOffersSections()

            Section {
                Button {
                    Task { await store.restorePurchases() }
                } label: {
                    HStack {
                        Text(String(localized: "support.restorePurchases"))
                        Spacer()
                        if store.isRestoring {
                            ProgressView()
                        }
                    }
                }
                .disabled(store.isBusy)

                Link(String(localized: "support.termsOfUse"), destination: SupportLinks.termsOfUse)
                Link(String(localized: "support.privacyPolicy"), destination: SupportLinks.privacyPolicy)
            }
        }
        // Loading isn't animated: the offers often arrive while the sheet is still sliding
        // up, and the placeholders have the same layout, so swapping them in place is seamless.
        .animation(.default, value: store.status)
        .animation(.default, value: store.activeSubscription)
        // Every completed purchase — one-time or a new subscription — is celebrated.
        .overlay {
            CelebrationBurst(trigger: store.celebrationCount)
                .ignoresSafeArea()
        }
        .sensoryFeedback(.success, trigger: store.celebrationCount)
        .manageSubscriptionsSheet(isPresented: $isManagingSubscription)
        .task { await store.load() }
    }
}

#if DEBUG
#Preview("Support") {
    NavigationStack {
        SupportView()
            .navigationTitle(String(localized: "button.supportTheDeveloper"))
    }
    .environment(SupportStore(service: PreviewSupportService()))
}

#Preview("Subscribed") {
    NavigationStack {
        SupportView()
    }
    .environment(SupportStore(service: PreviewSupportService(
        subscription: ActiveSupportSubscription(productID: .yearly, expirationDate: .now.addingTimeInterval(200 * 86_400), willAutoRenew: true)
    )))
}
#endif
