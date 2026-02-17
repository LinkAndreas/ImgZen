import Foundation
import UniformTypeIdentifiers

/// Represents lossless image formats that preserve all image data without compression artifacts.
enum LosslessImageFormat: String, CaseIterable, Sendable {
    case png = "PNG"
    case tiff = "TIFF"
    case bmp = "BMP"

    /// The file extension for this lossless format.
    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .tiff: return "tiff"
        case .bmp: return "bmp"
        }
    }

    /// The Uniform Type Identifier (UTI) for this lossless format.
    var utType: UTType? {
        switch self {
        case .png: return .png
        case .tiff: return .tiff
        case .bmp: return .bmp
        }
    }
}

extension LosslessImageFormat: Identifiable {
    var id: String { rawValue }
}
