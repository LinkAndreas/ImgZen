import Foundation

/// Extension providing title strings for LossyImageFormat.
extension LossyImageFormat {
    /// A user-friendly title for the lossy format.
    var title: String {
        switch self {
        case .jpeg:
            return "JPEG"
        case .heic:
            return "HEIC"
        case .webp:
            return "WEBP"
        }
    }
}
