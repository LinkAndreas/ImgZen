import SwiftUI

/// A heart and a short note on why support is welcome, at the top of Support the Developer.
/// Once someone has supported ImgZen — one-time or recurring — it thanks them instead,
/// marked as a supporter, for good.
struct SupportHeader: View {
    var hasSupported = false

    var body: some View {
        VStack(spacing: 14) {
            heart

            VStack(spacing: 6) {
                VStack(spacing: 2) {
                    // A small label over the title, rather than a badge of its own, so the heart
                    // stays the one accent.
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
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    // Short lines read better than ones that run the width of an iPad sheet.
                    .frame(maxWidth: 340)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .animation(.smooth, value: hasSupported)
    }

    private var heart: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 30, weight: .semibold))
            .foregroundStyle(.white)
            .symbolEffect(.bounce, value: hasSupported)
            .frame(width: 68, height: 68)
            .background(
                LinearGradient(colors: [.pink, .red], startPoint: .top, endPoint: .bottom),
                in: .circle
            )
            .shadow(color: .pink.opacity(0.35), radius: 10, y: 4)
            .accessibilityHidden(true)
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
