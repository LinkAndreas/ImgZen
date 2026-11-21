import SwiftUI

/// The app's settings in one form: the app icon, feedback, and about the app with what's new and its
/// version history.
struct SettingsView: View {
    let onSendFeedback: () -> Void
    let onShowWhatsNew: () -> Void

    var body: some View {
        Form {
            AppIconSection()

            FeedbackSection(onSendFeedback: onSendFeedback)

            AboutSection(onShowWhatsNew: onShowWhatsNew)
        }
        .navigationDestination(for: SettingsPage.self) { page in
            SettingsPageView(page: page)
        }
        .scrollContentBackground(.hidden)
        .background { AppBackground() }
        // Content scrolls softly under the sheet's title bar instead of being cut off at a hard edge.
        .scrollEdgeEffectStyle(.soft, for: .top)
        .navigationTitle(String(localized: "settings.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        SettingsView(onSendFeedback: {}, onShowWhatsNew: {})
    }
    .environment(AppIconStore.preview())
}
#endif
