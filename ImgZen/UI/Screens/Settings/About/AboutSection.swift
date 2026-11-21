import SwiftUI

/// About the app: what's new in the latest release, what changed in each version, the legal pages on
/// the website, the licenses of the open-source libraries, and the installed version.
struct AboutSection: View {
    let onShowWhatsNew: () -> Void

    var body: some View {
        Section {
            WhatsNewRow(action: onShowWhatsNew)

            NavigationLink(value: SettingsPage.versionHistory) {
                SettingsLabel(title: String(localized: "settings.versionHistory"), systemImage: "clock.arrow.circlepath")
            }

            // The pages open in the browser, in the language the app runs in.
            ExternalLinkRow(
                title: String(localized: "button.privacyPolicy"),
                systemImage: "hand.raised",
                destination: WebsiteLinks.privacyPolicy
            )
            ExternalLinkRow(
                title: String(localized: "settings.termsOfUse"),
                systemImage: "doc.text",
                destination: WebsiteLinks.termsOfUse
            )
            ExternalLinkRow(
                title: String(localized: "settings.legalNotice"),
                systemImage: "building.columns",
                destination: WebsiteLinks.legalNotice
            )

            // The licenses are in the app's page of the Settings app, from the settings bundle.
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                ExternalLinkRow(
                    title: String(localized: "settings.licenses"),
                    systemImage: "checkmark.seal",
                    destination: settingsURL,
                    accessibilityHint: String(localized: "settings.licensesHint")
                )
            }
        } header: {
            Text(String(localized: "settings.about.header"))
        } footer: {
            AppVersionFooter()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        Form {
            AboutSection(onShowWhatsNew: {})
        }
        .navigationDestination(for: SettingsPage.self) { page in
            SettingsPageView(page: page)
        }
    }
    .environment(AppIconStore.preview())
}
#endif
