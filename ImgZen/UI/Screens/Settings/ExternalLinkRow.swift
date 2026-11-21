import SwiftUI

/// A settings row that opens a page outside the app, such as the App Store or the website,
/// marked with an arrow so it's clear it leaves the app.
struct ExternalLinkRow: View {
    let title: String
    let systemImage: String
    let destination: URL
    /// What opens, for VoiceOver, when the title doesn't say.
    var accessibilityHint: String?

    var body: some View {
        Link(destination: destination) {
            HStack {
                SettingsLabel(title: title, systemImage: systemImage)
                Spacer()
                Image(systemName: "arrow.up.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(.rect)
        }
        .accessibilityHint(accessibilityHint.map { Text($0) } ?? Text(verbatim: ""))
    }
}

#if DEBUG
#Preview {
    Form {
        ExternalLinkRow(
            title: "Privacy Policy",
            systemImage: "hand.raised",
            destination: WebsiteLinks.privacyPolicy
        )
    }
}
#endif
