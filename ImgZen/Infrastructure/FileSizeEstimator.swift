import ImageIO
import SDWebImageWebPCoder
import UIKit

/// The estimated size of a converted image, next to the size of the original.
nonisolated struct FileSizeEstimate: Sendable, Equatable {
    let estimatedSize: Int64
    let originalSize: Int64
}

/// Estimates how large an image becomes in a lossy format at a given quality, off the main actor.
///
/// Encoding a 12-megapixel photo for every slider position would be too slow, so it encodes a copy
/// downsampled to at most `maxSamplePixelSize` and scales the result by the pixel count. Smaller images
/// compress slightly less well per pixel, so the estimate errs on the large side, which is the safer side.
nonisolated final class FileSizeEstimator: Sendable {
    // NSCache is thread-safe; the sample of the image being estimated is reused while the quality changes.
    nonisolated(unsafe) private let samples = NSCache<NSURL, Sample>()
    private let maxSamplePixelSize: CGFloat

    /// Creates a file size estimator.
    /// - Parameter maxSamplePixelSize: The longer side of the downsampled copy that's encoded.
    init(maxSamplePixelSize: CGFloat = 2048) {
        self.maxSamplePixelSize = maxSamplePixelSize
        samples.countLimit = 2
    }

    /// Estimates the size of an image converted to a lossy format.
    /// - Parameters:
    ///   - url: The file URL of the image.
    ///   - typeIdentifier: The type identifier of the format, for formats that ImageIO writes.
    ///   - usesWebPEncoder: Whether to encode WebP, which ImageIO can't write.
    ///   - quality: The compression quality from 0 to 1.
    /// - Returns: The estimate, or nil if the image can't be read or encoded.
    @concurrent
    func estimate(
        for url: URL,
        typeIdentifier: String,
        usesWebPEncoder: Bool,
        quality: Double
    ) async -> FileSizeEstimate? {
        guard let sample = sample(for: url), !Task.isCancelled else { return nil }

        let encodedSize: Int?
        if usesWebPEncoder {
            encodedSize = SDImageWebPCoder.shared.encodedData(
                with: UIImage(cgImage: sample.image),
                format: .webP,
                options: [.encodeCompressionQuality: quality]
            )?.count
        } else {
            let output = NSMutableData()
            if let destination = CGImageDestinationCreateWithData(output, typeIdentifier as CFString, 1, nil) {
                CGImageDestinationAddImage(
                    destination,
                    sample.image,
                    [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
                )
                encodedSize = CGImageDestinationFinalize(destination) ? output.length : nil
            } else {
                encodedSize = nil
            }
        }

        guard let encodedSize else { return nil }
        return FileSizeEstimate(
            estimatedSize: Int64((Double(encodedSize) * sample.pixelRatio).rounded()),
            originalSize: sample.originalSize
        )
    }

    /// Returns the downsampled copy of an image, creating it on first use.
    private func sample(for url: URL) -> Sample? {
        if let sample = samples.object(forKey: url as NSURL) {
            return sample
        }

        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? Int,
            let height = properties[kCGImagePropertyPixelHeight] as? Int,
            let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: maxSamplePixelSize
            ] as CFDictionary),
            image.width > 0, image.height > 0
        else {
            return nil
        }

        let originalSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        let sample = Sample(
            image: image,
            pixelRatio: max(1, Double(width * height) / Double(image.width * image.height)),
            originalSize: Int64(originalSize)
        )
        samples.setObject(sample, forKey: url as NSURL)
        return sample
    }

    /// A downsampled copy of an image, with what's needed to scale its encoded size to the original.
    private final class Sample {
        let image: CGImage
        /// How many times more pixels the original has.
        let pixelRatio: Double
        let originalSize: Int64

        init(image: CGImage, pixelRatio: Double, originalSize: Int64) {
            self.image = image
            self.pixelRatio = pixelRatio
            self.originalSize = originalSize
        }
    }
}
