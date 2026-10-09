import SwiftUI

/// A heart and a short note on why support is welcome, at the top of Support the Developer.
/// Once someone has supported ImgZen — one-time or recurring — it thanks them instead,
/// marked as a supporter, for good.
struct SupportHeader: View {
    var hasSupported = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 52))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.pink)
                .symbolEffect(.bounce, value: hasSupported)
                .accessibilityHidden(true)

            VStack(spacing: 2) {
                // A small label over the title, rather than a badge of its own, so the heart
                // above stays the one accent.
                if hasSupported {
                    Text(String(localized: "support.supporterBadge"))
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(0.6)
                        .foregroundStyle(.pink)
                        .transition(.opacity)
                }
                Text(String(localized: hasSupported ? "support.thankYouTitle" : "support.supportImgZen"))
                    .font(.title2.bold())
                    .contentTransition(.opacity)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Text(String(localized: hasSupported ? "support.yourSupportKeepsImgZenFree" : "support.imgZenIsFree"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .animation(.smooth, value: hasSupported)
    }
}

#if DEBUG
#Preview("Not yet") {
    SupportHeader()
        .padding()
}

#Preview("Supporter") {
    SupportHeader(hasSupported: true)
        .padding()
}
#endif
