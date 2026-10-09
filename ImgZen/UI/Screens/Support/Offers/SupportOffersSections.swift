import SwiftUI

/// The purchase options: placeholders while they load, a retry when they can't,
/// and one-time and recurring support once they're in.
struct SupportOffersSections: View {
    @Environment(SupportStore.self) private var store

    var body: some View {
        switch store.loadState {
        case .idle, .loading:
            // The same sections the offers will fill, as placeholders of the same
            // size — nothing jumps when the prices arrive, and nothing is tappable yet.
            SupportPlaceholderSection(oneTime: true, header: String(localized: "support.oneTimeSupport"), footer: String(localized: "support.aSinglePaymentNothing"))
            SupportPlaceholderSection(oneTime: false, header: String(localized: "support.recurringSupport"), footer: String(localized: "support.recurringSupportIsOptional"))

        case .unavailable:
            Section {
                Text(String(localized: "support.supportOptionsCouldnt"))
                    .foregroundStyle(.secondary)
                Button(String(localized: "button.tryAgain")) {
                    Task { await store.load() }
                }
            }

        case .loaded:
            if !store.oneTimeOffers.isEmpty {
                Section {
                    ForEach(store.oneTimeOffers) { offer in
                        SupportPurchaseRow(offer: offer, isProminent: true)
                    }
                } header: {
                    Text(String(localized: "support.oneTimeSupport"))
                } footer: {
                    Text(String(localized: "support.aSinglePaymentNothing"))
                }
            }

            if !store.subscriptionOffers.isEmpty {
                Section {
                    ForEach(store.subscriptionOffers) { offer in
                        SupportPurchaseRow(offer: offer, isProminent: false)
                    }
                } header: {
                    Text(String(localized: "support.recurringSupport"))
                } footer: {
                    Text(String(localized: "support.recurringSupportIsOptional"))
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    Form {
        SupportOffersSections()
    }
    .environment(SupportStore(service: PreviewSupportService()))
    .environment(AppIconStore.preview())
}
#endif
