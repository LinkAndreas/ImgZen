import Foundation

/// The app icons a supporter can choose from — the thank-you for recurring support.
///
/// Every icon but `classic` is an alternate icon set in the asset catalog
/// (`AppIcon-<Name>`), with a small `IconPreview-<Name>` image for the picker, since
/// app icon sets can't be loaded as images.
enum SupporterIcon: String, CaseIterable, Identifiable, Sendable {
    case classic = "Default"
    case midnight = "Midnight"
    case forest = "Forest"
    case rose = "Rose"
    case ocean = "Ocean"
    case graphite = "Graphite"

    var id: String { rawValue }

    /// The name `UIApplication.setAlternateIconName` takes; `nil` for the primary icon.
    var alternateIconName: String? {
        self == .classic ? nil : "AppIcon-\(rawValue)"
    }

    var previewImageName: String { "IconPreview-\(rawValue)" }

    /// The icon set as the app's icon, given `UIApplication.alternateIconName`.
    init(alternateIconName: String?) {
        self = Self.allCases.first { $0.alternateIconName == alternateIconName } ?? .classic
    }

    var title: String {
        switch self {
        case .classic: String(localized: "support.iconClassic")
        case .midnight: String(localized: "support.iconMidnight")
        case .forest: String(localized: "support.iconForest")
        case .rose: String(localized: "support.iconRose")
        case .ocean: String(localized: "support.iconOcean")
        case .graphite: String(localized: "support.iconGraphite")
        }
    }
}
