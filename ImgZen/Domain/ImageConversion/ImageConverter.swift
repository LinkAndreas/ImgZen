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
    // WebP files carry no orientation, so encode the pixels upright; otherwise
    // portrait photos, which cameras store sideways with an orientation tag, come out rotated.
    guard
        let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
        let cgImage = uprightImage(from: imageSource)
    else {
        return nil
    }
    let image = UIImage(cgImage: cgImage)

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

    // Formats whose orientation metadata isn't reliably honored (e.g. BMP, PNG) get upright pixels instead.
    let orientation = properties[kCGImagePropertyOrientation] as? UInt32 ?? 1
    if orientation != 1, !utType.supportsOrientationMetadata,
       let rotatedImage = uprightImage(from: imageSource) {
        cgImage = rotatedImage
        properties[kCGImagePropertyOrientation] = 1
        // The TIFF metadata repeats the orientation; left as is, viewers reading it would rotate the image again.
        if var tiffProperties = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            tiffProperties[kCGImagePropertyTIFFOrientation] = 1
            properties[kCGImagePropertyTIFFDictionary] = tiffProperties
        }
    }

    // JPEG has no transparency; without flattening, transparent areas would turn black.
    if utType.conforms(to: .jpeg), cgImage.hasAlpha, let flattenedImage = flattenedOntoWhite(cgImage) {
        cgImage = flattenedImage
    }

    CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
    CGImageDestinationFinalize(destination)

    return outputData as ImageData
}

/// Returns the first image of a source with its orientation applied to the pixels.
/// - Parameter imageSource: The source to read the image from.
/// - Returns: The upright image, or nil if it can't be decoded.
nonisolated private func uprightImage(from imageSource: CGImageSource) -> CGImage? {
    let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]
    let orientation = properties?[kCGImagePropertyOrientation] as? UInt32 ?? 1
    let width = properties?[kCGImagePropertyPixelWidth] as? Int ?? 0
    let height = properties?[kCGImagePropertyPixelHeight] as? Int ?? 0

    guard orientation != 1, max(width, height) > 0 else {
        return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    }

    // A thumbnail at full size is the image itself, rotated by ImageIO.
    return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: max(width, height)
    ] as CFDictionary)
}

/// Draws an image onto a white background, for formats without transparency.
/// - Parameter image: The image to flatten.
/// - Returns: The opaque image, or nil if drawing fails.
nonisolated private func flattenedOntoWhite(_ image: CGImage) -> CGImage? {
    // Keeps wide-gamut RGB color spaces such as Display P3; anything else is drawn in sRGB.
    let colorSpace = image.colorSpace.flatMap { $0.model == .rgb ? $0 : nil }
        ?? CGColorSpace(name: CGColorSpace.sRGB)
    guard
        let colorSpace,
        let context = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
    else {
        return nil
    }

    let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
    context.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
    context.fill(rect)
    context.draw(image, in: rect)
    return context.makeImage()
}

private extension CGImage {
    /// Whether the image has an alpha channel.
    nonisolated var hasAlpha: Bool {
        switch alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast:
            return false
        default:
            return true
        }
    }
}

private extension UTType {
    /// Whether the orientation metadata of files of this type is honored widely enough to rely on it.
    /// PNG can store it too, but many apps and browsers ignore it and would show the image rotated.
    nonisolated var supportsOrientationMetadata: Bool {
        [UTType.jpeg, .heic, .tiff].contains { conforms(to: $0) }
    }
}
