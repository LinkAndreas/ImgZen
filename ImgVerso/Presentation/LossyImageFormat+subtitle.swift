import Foundation

/// Extension providing subtitle descriptions for LossyImageFormat.
extension LossyImageFormat {
    /// A user-friendly subtitle describing the lossy format's characteristics.
    var subtitle: String {
        switch self {
        case .jpeg:
            return String(localized: "format.jpeg.subtitle")
        case .heic:
            return String(localized: "format.heic.subtitle")
        case .webp:
            return String(localized: "format.webp.subtitle")
        }
    }
}
