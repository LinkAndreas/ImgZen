import Foundation

/// Links shown with the purchase options, as App Review requires for subscriptions.
/// Both pages are published in every language the app supports and open in the
/// language the app runs in.
enum SupportLinks {
    static var termsOfUse: URL { page("termsofuse") }
    static var privacyPolicy: URL { page("privacy") }

    /// The app's languages, each with its own page; any other language gets English.
    private static let languages: Set<String> = ["de", "en"]

    private static func page(_ name: String) -> URL {
        let language = Bundle.main.preferredLocalizations.first
            .flatMap { Locale(identifier: $0).language.languageCode?.identifier }
            .flatMap { languages.contains($0) ? $0 : nil } ?? "en"
        return URL(string: "https://imgzen.linkandreas.de/\(name)/\(language)/")!
    }
}
