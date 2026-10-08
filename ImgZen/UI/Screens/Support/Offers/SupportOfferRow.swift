import SwiftUI

struct SupportOfferRow: View {
    let offer: SupportOffer
    /// One-time support gets filled price buttons; recurring support is quieter.
    let isProminent: Bool
    let isActive: Bool
    let isPurchasing: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(verbatim: offer.id.emoji)
                .font(.title2)
                // A fixed column, so the offer names all start at the same x.
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(offer.displayName)
                    .font(.body.weight(.semibold))
                if !offer.description.isEmpty {
                    Text(offer.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                // The billing period sits with the name, so every price button stays
                // one line and the same size.
                if let period = offer.billingPeriod {
                    Text(verbatim: period.billingText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)

            VStack {
                if isActive {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text(String(localized: "support.active"))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                } else {
                    SupportPriceButton(
                        offer: offer,
                        isProminent: isProminent,
                        isPurchasing: isPurchasing,
                        isDisabled: isDisabled,
                        action: action
                    )
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    List {
        SupportOfferRow(
            offer: PreviewSupportService.sampleOffers[0],
            isProminent: true,
            isActive: false,
            isPurchasing: false,
            isDisabled: false
        ) {}
        SupportOfferRow(
            offer: PreviewSupportService.sampleOffers[3],
            isProminent: false,
            isActive: true,
            isPurchasing: false,
            isDisabled: false
        ) {}
    }
}
#endif
