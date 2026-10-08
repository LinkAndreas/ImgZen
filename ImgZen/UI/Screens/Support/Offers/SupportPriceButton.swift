import SwiftUI

/// An offer's price as the button that buys it, with a spinner while it does.
struct SupportPriceButton: View {
    let offer: SupportOffer
    /// One-time support gets a filled button; recurring support a quieter one.
    let isProminent: Bool
    let isPurchasing: Bool
    let isDisabled: Bool
    let action: () -> Void

    /// Every price button is at least this wide, so the buttons line up in a column.
    private static let priceMinimumWidth: CGFloat = 58

    private var priceLabel: String {
        offer.billingPeriod.map { "\(offer.displayPrice), \($0.billingText)" } ?? offer.displayPrice
    }

    var body: some View {
        let button = Button(action: action) {
            // Just the price: one line, never wrapped, and every button at least the
            // same width, so the buttons line up in a column.
            Text(verbatim: offer.displayPrice)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            .minimumScaleFactor(0.8)
            .monospacedDigit()
            .frame(minWidth: Self.priceMinimumWidth)
            // Keeps the button's size while the spinner shows.
            .opacity(isPurchasing ? 0 : 1)
            .overlay {
                if isPurchasing {
                    ProgressView()
                }
            }
        }
        .buttonBorderShape(.capsule)
        .disabled(isDisabled)
        .accessibilityLabel(Text(verbatim: "\(offer.displayName), \(priceLabel)"))

        if isProminent {
            button.buttonStyle(.borderedProminent)
        } else {
            button.buttonStyle(.bordered)
        }
    }
}

#if DEBUG
#Preview {
    HStack {
        SupportPriceButton(offer: PreviewSupportService.sampleOffers[0], isProminent: true, isPurchasing: false, isDisabled: false) {}
        SupportPriceButton(offer: PreviewSupportService.sampleOffers[0], isProminent: false, isPurchasing: true, isDisabled: false) {}
    }
    .padding()
}
#endif
