import Foundation

/// Pages on ImgZen's website. Each is published in every language the app supports and opens in the
/// language the app runs in.
nonisolated enum WebsiteLinks {
    static var privacyPolicy: URL { page("privacy") }

    /// The app's languages, each with its own page; any other language gets English.
    private static let languages: Set<String> = ["de", "en"]

    /// The page in the given localization, English if the site doesn't have it.
    static func page(_ name: String, localization: String? = Bundle.main.preferredLocalizations.first) -> URL {
        let language = localization
            .flatMap { Locale(identifier: $0).language.languageCode?.identifier }
            .flatMap { languages.contains($0) ? $0 : nil } ?? "en"
        return URL(string: "https://imgzen.linkandreas.de/\(name)/\(language)/")!
    }
}
