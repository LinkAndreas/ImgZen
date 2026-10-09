import StoreKit
import SwiftUI

/// Support the Developer: a quiet, optional way to pay for ImgZen's development.
/// No feature is locked — the app stays fully free. Recurring support unlocks the
/// supporter app icons as a thank-you.
struct SupportView: View {
    @Environment(SupportStore.self) private var store
    @State private var isManagingSubscription = false

    var body: some View {
        Form {
            Section {
                SupportHeader(hasSupported: store.hasSupported)
            }
            .listRowBackground(Color.clear)
            // Closer to the navigation bar: the header opens the screen rather than being a card in it.
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
            .listSectionMargins(.top, 0)

            if let status = store.status {
                Section {
                    SupportStatusRow(status: status)
                }
            }

            // A renewal that couldn't be charged pauses recurring support until the payment is fixed.
            if store.hasBillingIssue {
                Section {
                    Label(String(localized: "support.paymentProblem"), systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Button(String(localized: "support.manageSubscription")) {
                        isManagingSubscription = true
                    }
                }
            }

            // A subscriber's plan shows, with Manage Subscription, among the recurring offers.
            SupportOffersSections { isManagingSubscription = true }

            // Without the offers, the subscription and its management still show.
            if let subscription = store.activeSubscription, store.subscriptionOffers.isEmpty {
                Section {
                    ActiveSubscriptionRow(subscription: subscription)
                    Button(String(localized: "support.manageSubscription")) {
                        isManagingSubscription = true
                    }
                }
            }

            // What recurring support unlocks, right below it: locked until someone subscribes,
            // and the picker once they have. Supporters keep it even when the offers can't load.
            if store.isSupporter || !store.subscriptionOffers.isEmpty {
                SupporterIconsSection(isUnlocked: store.isSupporter)
            }

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
        .animation(.default, value: store.hasBillingIssue)
        .scrollContentBackground(.hidden)
        .background { AppBackground() }
        // Every completed purchase — one-time or a new subscription — is celebrated.
        .overlay {
            CelebrationBurst(trigger: store.celebrationCount)
                .ignoresSafeArea()
        }
        .sensoryFeedback(.success, trigger: store.celebrationCount)
        .manageSubscriptionsSheet(isPresented: $isManagingSubscription)
        // Cancelling or switching plans there changes no transaction, so read the subscription again
        // once the sheet closes. Coming back from Settings, the app reads it again (`ImgZenApp`).
        .onChange(of: isManagingSubscription) { _, isManaging in
            if !isManaging { Task { await store.refreshSubscription() } }
        }
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
    .environment(AppIconStore.preview())
}

#Preview("Subscribed") {
    NavigationStack {
        SupportView()
    }
    .environment(SupportStore(service: PreviewSupportService(
        subscription: ActiveSupportSubscription(productID: .yearly, expirationDate: .now.addingTimeInterval(200 * 86_400), willAutoRenew: true)
    )))
    .environment(AppIconStore.preview(.ember))
}
#endif
