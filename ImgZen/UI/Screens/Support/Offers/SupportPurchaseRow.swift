import SwiftUI

/// An offer from the store, bought when its price is tapped.
struct SupportPurchaseRow: View {
    let offer: SupportOffer
    /// One-time support gets filled price buttons; recurring support is quieter.
    let isProminent: Bool

    @Environment(SupportStore.self) private var store

    var body: some View {
        SupportOfferRow(
            offer: offer,
            isProminent: isProminent,
            isActive: store.activeSubscription?.productID == offer.id,
            activeDetail: store.activeSubscription?.renewalText,
            isPurchasing: store.purchasingProductID == offer.id,
            isDisabled: store.isBusy
        ) {
            Task { await store.purchase(offer) }
        }
    }
}

#if DEBUG
#Preview {
    List {
        SupportPurchaseRow(offer: PreviewSupportService.sampleOffers[0], isProminent: true)
    }
    .environment(SupportStore(service: PreviewSupportService()))
}
#endif
