import Foundation
import UniformTypeIdentifiers

/// Represents lossy image formats that use compression to reduce file size.
enum LossyImageFormat: String, CaseIterable, Sendable {
    case jpeg = "JPEG"
    case heic = "HEIC"
    case webp = "WebP"

    /// The file extension for this lossy format.
    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .heic: return "heic"
        case .webp: return "webp"
        }
    }

    /// The Uniform Type Identifier (UTI) for this lossy format.
    var utType: UTType? {
        switch self {
        case .jpeg: return .jpeg
        case .heic: return .heic
        case .webp: return UTType(filenameExtension: "webp")
        }
    }
}

extension LossyImageFormat: Identifiable {
    var id: String { rawValue }
}
