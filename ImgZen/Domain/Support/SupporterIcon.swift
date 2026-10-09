import Foundation

/// The app icons a supporter can choose from — the thank-you for recurring support.
///
/// Every icon but `classic` is an alternate icon set in the asset catalog
/// (`AppIcon-<Name>`), with a small `IconPreview-<Name>` image for the picker, since
/// app icon sets can't be loaded as images.
enum SupporterIcon: String, CaseIterable, Identifiable, Sendable {
    case classic = "Default"
    case amethyst = "Amethyst"
    case aurora = "Aurora"
    case blush = "Blush"
    case cyberLime = "CyberLime"
    case dune = "Dune"
    case ember = "Ember"
    case evergreen = "Evergreen"
    case glacier = "Glacier"
    case lagoon = "Lagoon"
    case matcha = "Matcha"
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
        case .aurora: String(localized: "support.iconAurora")
        case .blush: String(localized: "support.iconBlush")
        case .cyberLime: String(localized: "support.iconCyberLime")
        case .dune: String(localized: "support.iconDune")
        case .ember: String(localized: "support.iconEmber")
        case .evergreen: String(localized: "support.iconEvergreen")
        case .glacier: String(localized: "support.iconGlacier")
        case .lagoon: String(localized: "support.iconLagoon")
        case .matcha: String(localized: "support.iconMatcha")
        case .midnightGold: String(localized: "support.iconMidnightGold")
        case .noir: String(localized: "support.iconNoir")
        }
    }
}
