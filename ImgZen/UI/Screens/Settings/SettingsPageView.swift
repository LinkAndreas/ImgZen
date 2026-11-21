import SwiftUI

/// The screen of a page the settings lead to.
struct SettingsPageView: View {
    let page: SettingsPage

    var body: some View {
        switch page {
        case .versionHistory:
            VersionHistoryView()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsPageView(page: .versionHistory)
    }
    .environment(AppIconStore.preview())
}
#endif
