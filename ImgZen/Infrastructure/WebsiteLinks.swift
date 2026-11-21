import Foundation

/// Pages on ImgZen's website. Each is published in every language the app supports and opens in the
/// language the app runs in.
nonisolated enum WebsiteLinks {
    static var privacyPolicy: URL { page("privacy") }
    static var termsOfUse: URL { page("termsofuse") }
    /// The legal notice (Impressum).
    static var legalNotice: URL { page("imprint") }

    /// The app's languages (by language code), each with the path of its pages on the website;
    /// any other language gets English.
    private static let languages: [String: String] = [
        "de": "de", "en": "en", "es": "es", "fr": "fr", "it": "it",
        "ja": "ja", "ko": "ko", "nl": "nl", "pt": "pt-br", "ru": "ru", "zh": "zh",
    ]

    /// The page in the given localization, English if the site doesn't have it.
    static func page(_ name: String, localization: String? = Bundle.main.preferredLocalizations.first) -> URL {
        let language = localization
            .flatMap { Locale(identifier: $0).language.languageCode?.identifier }
            .flatMap { languages[$0] } ?? "en"
        return URL(string: "https://imgzen.linkandreas.de/\(name)/\(language)/")!
    }
}
