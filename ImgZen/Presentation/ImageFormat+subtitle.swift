import Foundation

/// Extension providing subtitle descriptions for ImageFormat.
extension ImageFormat {
    /// A user-friendly subtitle describing the format's characteristics.
    var subtitle: String {
        switch self {
        case let .lossless(format):
            return format.subtitle
        case let .lossy(format, _):
            return format.subtitle
        }
    }
}
