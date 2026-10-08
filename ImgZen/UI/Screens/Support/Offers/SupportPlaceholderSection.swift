import SwiftUI

/// Redacted, gently pulsing rows standing in for one kind of offer while loading.
struct SupportPlaceholderSection: View {
    let oneTime: Bool
    let header: String
    let footer: String

    var body: some View {
        Section {
            ForEach(SupportProductID.allCases.filter { $0.kind == (oneTime ? .oneTime : .subscription) }, id: \.self) { id in
                SupportOfferRow(
                    offer: Self.placeholderOffer(id),
                    isProminent: oneTime,
                    isActive: false,
                    isPurchasing: false,
                    isDisabled: true,
                    action: {}
                )
            }
            .redacted(reason: .placeholder)
            .phaseAnimator([false, true]) { rows, isBright in
                rows.opacity(isBright ? 1 : 0.5)
            } animation: { _ in
                .easeInOut(duration: 0.9)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(String(localized: "support.loadingSupportOptions")))
        } header: {
            Text(header)
        } footer: {
            Text(footer)
        }
    }

    /// A stand-in with the shape of a real offer; its text is redacted.
    private static func placeholderOffer(_ id: SupportProductID) -> SupportOffer {
        SupportOffer(
            id: id,
            displayName: "Support option",
            description: "",
            displayPrice: "0,00 €",
            billingPeriod: id.kind == .subscription ? .month : nil
        )
    }
}

#if DEBUG
#Preview {
    Form {
        SupportPlaceholderSection(oneTime: true, header: String(localized: "support.oneTimeSupport"), footer: String(localized: "support.aSinglePaymentNothing"))
    }
}
#endif
