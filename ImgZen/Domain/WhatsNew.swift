import Foundation

/// What a release brings, shown once to people who already used ImgZen, and any time from
/// Settings › About.
nonisolated enum WhatsNew {
    /// The release these features came with; raising it shows the sheet again.
    static let version = "1.9"

    /// One new feature: its symbol, what it is, and where to try it.
    struct Feature: Identifiable, Sendable {
        /// Where a feature can be tried right away.
        enum Destination: Sendable {
            /// The app's settings.
            case settings
            /// The version history in the app's settings.
            case versionHistory
            /// The app's page in the Settings app, where a language can be picked for ImgZen alone.
            case languageSettings

            /// The button that goes there.
            var title: LocalizedStringResource {
                switch self {
                case .settings: "whatsNew.openSettings"
                case .versionHistory: "whatsNew.openVersionHistory"
                case .languageSettings: "whatsNew.changeLanguage"
                }
            }
        }

        let id: String
        let systemImage: String
        let title: LocalizedStringResource
        let text: LocalizedStringResource
        var destination: Destination?
    }

    static let features: [Feature] = [
        Feature(
            id: "settings", systemImage: "gearshape",
            title: "whatsNew.settings.title", text: "whatsNew.settings.text",
            destination: .settings
        ),
        Feature(
            id: "versionHistory", systemImage: "clock.arrow.circlepath",
            title: "whatsNew.versionHistory.title", text: "whatsNew.versionHistory.text",
            destination: .versionHistory
        ),
        Feature(
            id: "languages", systemImage: "globe",
            title: "whatsNew.languages.title", text: "whatsNew.languages.text",
            destination: .languageSettings
        ),
    ]

    /// After an update, for people who already used ImgZen; new users get the onboarding instead.
    /// - Parameters:
    ///   - lastSeen: The version of the What's New the user last saw, if any.
    ///   - hasCompletedOnboarding: Whether the user has finished or skipped the onboarding.
    static func shouldShow(lastSeen: String?, hasCompletedOnboarding: Bool) -> Bool {
        hasCompletedOnboarding && lastSeen != version
    }
}
