import Foundation
import UniformTypeIdentifiers

/// Represents an image format, either lossless or lossy with optional compression quality.
enum ImageFormat {
    case lossless(LosslessImageFormat)
    case lossy(LossyImageFormat, compressionQuality: ImageCompressionQuality = 1.0)

    /// The file extension for this image format (e.g., "png", "jpg").
    var fileExtension: String {
        switch self {
        case let .lossless(format):
            return format.fileExtension
        case let .lossy(format, _):
            return format.fileExtension
        }
    }

    /// The Uniform Type Identifier (UTI) for this image format.
    var utType: UTType? {
        switch self {
        case let .lossless(format):
            return format.utType
        case let .lossy(format, _):
            return format.utType
        }
    }

    /// Returns true if this format is lossy (compressed).
    var isLossy: Bool {
        switch self {
        case .lossless:
            return false
        case .lossy:
            return true
        }
    }

    /// Returns the lossless format if this is a lossless format, otherwise nil.
    var losslessFormat: LosslessImageFormat? {
        switch self {
        case let .lossless(format):
            return format
        case .lossy:
            return nil
        }
    }

    /// Returns the lossy format if this is a lossy format, otherwise nil.
    var lossyFormat: LossyImageFormat? {
        switch self {
        case let .lossy(format, _):
            return format
        case .lossless:
            return nil
        }
    }
}

extension ImageFormat: Identifiable {
    var id: String {
        switch self {
        case let .lossless(format):
            return format.id
        case let .lossy(format, _):
            return format.id
        }
    }
}

extension ImageFormat: CaseIterable {
    static var allCases: [ImageFormat] {
        return [
            .lossless(.png),
            .lossless(.bmp),
            .lossless(.tiff)
        ]
    }
}

extension ImageFormat: Equatable {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.lossy(lhsFormat, lhsCompressionQuality), .lossy(rhsFormat, rhsCompressionQuality)):
            return lhsFormat == rhsFormat && lhsCompressionQuality == rhsCompressionQuality
        case let (.lossless(lhsFormat), .lossless(rhsFormat)):
            return lhsFormat == rhsFormat
        default:
            return false
        }
    }
}
