import Foundation

/// Extension providing subtitle descriptions for LosslessImageFormat.
extension LosslessImageFormat {
    /// A user-friendly subtitle describing the lossless format's characteristics.
    var subtitle: String {
        switch self {
        case .bmp:
            return String(localized: "format.bmp.subtitle")
        case .png:
            return String(localized: "format.png.subtitle")
        case .tiff:
            return String(localized: "format.tiff.subtitle")
        }
    }
}
