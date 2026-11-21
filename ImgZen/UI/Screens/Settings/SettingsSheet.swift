import SwiftUI

/// The settings as a sheet, opened with the gear in the main screen's toolbar: full height on iPhone,
/// a centred form on iPad.
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isMailComposerPresented = false

    var body: some View {
        NavigationStack {
            SettingsView(onSendFeedback: { isMailComposerPresented = true })
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
        .presentationSizing(.form)
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
