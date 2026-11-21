import SwiftUI

/// Shares ImgZen's App Store page with a friend.
struct ShareAppRow: View {
    var body: some View {
        ShareLink(
            item: AppStoreLinks.app,
            subject: Text(verbatim: "ImgZen"),
            message: Text(String(localized: "settings.feedback.shareMessage"))
        ) {
            SettingsLabel(title: String(localized: "settings.feedback.share"), systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
    }
}

#if DEBUG
#Preview {
    Form {
        ShareAppRow()
    }
}
#endif
