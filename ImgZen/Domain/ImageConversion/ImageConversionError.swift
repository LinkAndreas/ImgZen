import Foundation

/// Errors that can occur during image conversion operations.
enum ImageConversionError: Error, Sendable {
    case invalidInputData
    case conversionFailed
    case unsupportedFormat
}
