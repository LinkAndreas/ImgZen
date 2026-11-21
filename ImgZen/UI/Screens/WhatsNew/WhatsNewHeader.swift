import SwiftUI

/// The What's New sheet's title, with the app's logo and the release it's about.
struct WhatsNewHeader: View {
    var body: some View {
        VStack(spacing: 12) {
            AppLogo(size: 72)
            Text(String(localized: "whatsNew.title"))
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: "ImgZen \(WhatsNew.version)")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview {
    WhatsNewHeader()
        .environment(AppIconStore.preview())
}
#endif
