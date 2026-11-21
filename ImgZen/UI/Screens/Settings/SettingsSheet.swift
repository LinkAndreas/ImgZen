import SwiftUI

/// The settings as a sheet, opened with the gear in the main screen's toolbar: full height on iPhone,
/// a centred form on iPad.
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var path: [SettingsPage]
    @State private var isMailComposerPresented = false
    @State private var isWhatsNewPresented = false
    /// Where a feature of What's New is tried, once its sheet has closed.
    @State private var whatsNewDestination: WhatsNew.Feature.Destination?

    /// - Parameter initialPage: The page the settings open on, e.g. the version history from What's New.
    init(initialPage: SettingsPage? = nil) {
        _path = State(initialValue: initialPage.map { [$0] } ?? [])
    }

    var body: some View {
        NavigationStack(path: $path) {
            SettingsView(
                onSendFeedback: { isMailComposerPresented = true },
                onShowWhatsNew: { isWhatsNewPresented = true }
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // The system close button: an ✕ with the localized "Close" label.
                    Button(role: .close) { dismiss() }
                }
            }
        }
        // On top of the settings, so writing feedback returns to them when it's sent or cancelled.
        .mailComposer(
            isPresenting: $isMailComposerPresented,
            recipients: ["feedback@linkandreas.de"],
            subject: String(localized: "mail.feedbackSubject"),
            body: String(localized: "mail.feedbackBody")
        )
        // Also on top of the settings, which it returns to; trying a feature goes there once it's closed.
        .sheet(isPresented: $isWhatsNewPresented, onDismiss: tryWhatsNewDestination) {
            WhatsNewView(
                onTry: { destination in
                    whatsNewDestination = destination
                    isWhatsNewPresented = false
                },
                onDone: { isWhatsNewPresented = false }
            )
            .presentationSizing(.form)
        }
        .presentationSizing(.form)
    }

    /// Goes where the feature tried in What's New is: the settings are already open, so their first page,
    /// or the version history, or the app's page in the Settings app to pick a language.
    private func tryWhatsNewDestination() {
        guard let destination = whatsNewDestination else { return }
        whatsNewDestination = nil

        switch destination {
        case .settings:
            path = []
        case .versionHistory:
            path = [.versionHistory]
        case .languageSettings:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
        }
    }
}

#if DEBUG
#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            SettingsSheet()
        }
        .environment(AppIconStore.preview())
}
#endif
