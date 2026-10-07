import UIKit
import ImageIO
import UniformTypeIdentifiers
import SDWebImageWebPCoder

/// Main namespace for image conversion functionality.
enum ImageConverter {
    /// Converts image data to the specified format.
    /// - Parameters:
    ///   - imageData: The source image data to convert.
    ///   - format: The target image format.
    /// - Returns: Converted image data, or nil if conversion fails.
    @concurrent
    static func convertImageData(
        _ imageData: Data,
        to format: ImageFormat
    ) async -> ImageData? {
        switch format {
        case let .lossy(.webp, compressionQuality):
            return await convertImageDataUsingWebP(imageData, compressionQuality: compressionQuality)
        default:
            return await convertImageDataUsingImageIO(imageData, to: format)
        }
    }
}

/// Converts image data to WebP format using SDWebImageWebPCoder.
/// - Parameters:
///   - imageData: The source image data.
///   - compressionQuality: Compression quality from 0.0 to 1.0. Defaults to 1.0.
/// - Returns: WebP-encoded image data, or nil if conversion fails.
@concurrent
private func convertImageDataUsingWebP(
    _ imageData: ImageData,
    compressionQuality: Double = 1.0
) async -> ImageData? {
    guard let image = UIImage(data: imageData) else { return nil }

    return SDImageWebPCoder.shared.encodedData(
        with: image,
        format: .webP,
        options: [.encodeCompressionQuality: compressionQuality]
    )
}

/// Converts image data using ImageIO framework (supports most standard formats).
/// - Parameters:
///   - imageData: The source image data.
///   - format: The target image format.
/// - Returns: Converted image data, or nil if conversion fails.
@concurrent
private func convertImageDataUsingImageIO(
    _ imageData: ImageData,
    to format: ImageFormat
) async -> ImageData? {
    // Create CGImageSource from input data (no UIImage needed)
    guard
        let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
        var cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    else {
        return nil
    }

    // Convert using CGImageDestination
    guard let utType = await format.utType else { return nil }

    let outputData = NSMutableData()

    guard let destination = CGImageDestinationCreateWithData(
        outputData as CFMutableData,
        utType.identifier as CFString,
        1,
        nil
    ) else { return nil }

    // Get original image properties including orientation
    let sourceProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]

    // Apply compression properties while preserving orientation
    var properties: [CFString: Any] = sourceProperties ?? [:]
    if case let .lossy(_, compressionQuality) = format {
        properties[kCGImageDestinationLossyCompressionQuality] = compressionQuality
    }

    // Formats without EXIF support (e.g. BMP) drop the orientation, so rotate the pixels instead.
    let orientation = properties[kCGImagePropertyOrientation] as? UInt32 ?? 1
    if orientation != 1, !utType.supportsOrientationMetadata,
       let uprightImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, [
           kCGImageSourceCreateThumbnailFromImageAlways: true,
           kCGImageSourceCreateThumbnailWithTransform: true,
           kCGImageSourceThumbnailMaxPixelSize: max(cgImage.width, cgImage.height)
       ] as CFDictionary) {
        cgImage = uprightImage
        properties[kCGImagePropertyOrientation] = 1
    }

    CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
    CGImageDestinationFinalize(destination)

    return outputData as ImageData
}

private extension UTType {
    /// Whether ImageIO can store the EXIF orientation in files of this type.
    nonisolated var supportsOrientationMetadata: Bool {
        [UTType.jpeg, .heic, .png, .tiff].contains { conforms(to: $0) }
    }
}
