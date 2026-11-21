import SwiftUI

/// Writes to the developer: an email with the app and device details filled in.
struct SendFeedbackRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsLabel(title: String(localized: "button.sendFeedback"), systemImage: "envelope")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
        .accessibilityHint(Text(String(localized: "settings.feedback.sendHint")))
    }
}

#if DEBUG
#Preview {
    Form {
        SendFeedbackRow {}
    }
}
#endif
