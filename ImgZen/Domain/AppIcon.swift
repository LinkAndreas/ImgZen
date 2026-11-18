import Foundation

/// The app icons to choose from: the icon ImgZen shows on the Home Screen, which the app also takes
/// its logo and colors from.
///
/// Every icon but `classic` is an alternate icon set in the asset catalog
/// (`AppIcon-<Name>`), with a small `IconPreview-<Name>` image for the picker, since
/// app icon sets can't be loaded as images.
enum AppIcon: String, CaseIterable, Identifiable, Sendable {
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
        case .classic: String(localized: "appIcon.classic")
        case .amethyst: String(localized: "appIcon.amethyst")
        case .blush: String(localized: "appIcon.blush")
        case .ember: String(localized: "appIcon.ember")
        case .glacier: String(localized: "appIcon.glacier")
        case .lagoon: String(localized: "appIcon.lagoon")
        case .midnightGold: String(localized: "appIcon.midnightGold")
        case .noir: String(localized: "appIcon.noir")
        }
    }
}
