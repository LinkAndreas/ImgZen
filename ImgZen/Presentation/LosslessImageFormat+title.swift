import Foundation

/// Extension providing title strings for LosslessImageFormat.
extension LosslessImageFormat {
    /// A user-friendly title for the lossless format.
    var title: String {
        switch self {
        case .bmp:
            return "BMP"
        case .png:
            return "PNG"
        case .tiff:
            return "TIFF"
        }
    }
}
