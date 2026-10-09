import Foundation

/// The app icons a supporter can choose from — the thank-you for recurring support.
///
/// Every icon but `classic` is an alternate icon set in the asset catalog
/// (`AppIcon-<Name>`), with a small `IconPreview-<Name>` image for the picker, since
/// app icon sets can't be loaded as images.
enum SupporterIcon: String, CaseIterable, Identifiable, Sendable {
    case classic = "Default"
    case amethyst = "Amethyst"
    case blush = "Blush"
    case ember = "Ember"
    case glacier = "Glacier"
    case lagoon = "Lagoon"
    case midnightGold = "MidnightGold"
    case noir = "Noir"

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
        case .amethyst: String(localized: "support.iconAmethyst")
        case .blush: String(localized: "support.iconBlush")
        case .ember: String(localized: "support.iconEmber")
        case .glacier: String(localized: "support.iconGlacier")
        case .lagoon: String(localized: "support.iconLagoon")
        case .midnightGold: String(localized: "support.iconMidnightGold")
        case .noir: String(localized: "support.iconNoir")
        }
    }
}
