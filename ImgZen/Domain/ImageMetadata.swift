import Foundation

/// Metadata information for an image file or asset, including dimensions, size, and format.
struct ImageMetadata {
    let filename: String
    let fileExtension: String
    let fileSize: Int64
    let dimensions: CGSize
    let contentType: String
}
