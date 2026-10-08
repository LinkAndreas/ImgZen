import ImageIO
import UIKit

/// The metadata and thumbnail shown for an image in a gallery.
nonisolated struct ImagePreview: Sendable {
    let metadata: ImageMetadata
    let thumbnail: UIImage?
}

/// Loads the previews shown in the galleries, off the main actor, and keeps recent ones in memory.
///
/// Thumbnails are decoded while they're created, not when they're first drawn, so showing them
/// costs the main thread nothing. The cache lets cells that scroll back into view show their image
/// at once instead of loading it again.
nonisolated final class ImagePreviewLoader: Sendable {
    // NSCache is thread-safe and evicts entries under memory pressure.
    nonisolated(unsafe) private let cache = NSCache<NSString, Entry>()
    private let repository: ImageFromURLRepository
    private let maxPixelSize: CGFloat

    /// Creates a preview loader.
    /// - Parameters:
    ///   - repository: Reads the metadata of images.
    ///   - maxPixelSize: Maximum pixel size of the thumbnails' longer side.
    ///   - cacheLimit: Maximum number of bytes of decoded thumbnails kept in memory.
    init(
        repository: ImageFromURLRepository = ImageFromURLRepository(),
        maxPixelSize: CGFloat = Constants.thumbnailSize,
        cacheLimit: Int = 96 * 1024 * 1024
    ) {
        self.repository = repository
        self.maxPixelSize = maxPixelSize
        cache.totalCostLimit = cacheLimit
    }

    /// Returns the preview stored under a key if it's in memory, without loading it.
    /// - Parameter key: Identifies the image, e.g. the ID of the gallery item showing it.
    func cachedPreview(forKey key: String) -> ImagePreview? {
        cache.object(forKey: key as NSString)?.preview
    }

    /// Returns the preview of an image, loading it on a background thread unless it's in memory.
    /// - Parameters:
    ///   - url: The file URL of the image.
    ///   - key: Identifies the image in the cache, e.g. the ID of the gallery item showing it.
    @concurrent
    func preview(for url: URL, cacheKey key: String) async throws -> ImagePreview {
        if let preview = cachedPreview(forKey: key) {
            return preview
        }

        try Task.checkCancellation()
        let metadata = try repository.metadata(for: url)
        let thumbnail = Self.decodedThumbnail(for: url, maxPixelSize: maxPixelSize)
        let preview = ImagePreview(metadata: metadata, thumbnail: thumbnail)

        let cost = thumbnail.map { Int($0.size.width * $0.size.height * $0.scale * $0.scale) * 4 } ?? 0
        cache.setObject(Entry(preview: preview), forKey: key as NSString, cost: cost)
        return preview
    }

    /// Creates a thumbnail that's already decoded, using ImageIO's downsampling,
    /// which reads only as much of the file as the thumbnail needs.
    private static func decodedThumbnail(for url: URL, maxPixelSize: CGFloat) -> UIImage? {
        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary

        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions),
            let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions)
        else {
            return nil
        }

        return UIImage(cgImage: thumbnail)
    }

    /// Wraps a preview for NSCache, which only stores objects.
    private final class Entry {
        let preview: ImagePreview

        init(preview: ImagePreview) {
            self.preview = preview
        }
    }
}
