import ImageIO
import Foundation
import UIKit

/// Repository implementation for loading images from file URLs.
struct ImageFromURLRepository: ImageRepository {
    private let fileManager: FileManager

    /// Creates an ImageFromURLRepository.
    /// - Parameter fileManager: FileManager instance to use. Defaults to `.default`.
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Retrieves metadata for an image at the given file URL.
    /// - Parameter source: The file URL of the image.
    /// - Returns: Image metadata including dimensions, size, and format.
    /// - Throws: Errors if metadata cannot be retrieved.
    func metadata(
        for source: URL
    ) throws -> ImageMetadata {
        let didStartAccess = source.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                source.stopAccessingSecurityScopedResource()
            }
        }

        let attributes = try fileManager.attributesOfItem(atPath: source.path)
        let resourceValues = try source.resourceValues(forKeys: [
            .nameKey,
            .typeIdentifierKey
        ])

        let filePath = resourceValues.name ?? source.lastPathComponent
        let fileSize = attributes[.size] as? Int64 ?? 0
        let contentType = resourceValues.typeIdentifier ?? "public.image"
        let dimensions = getImageDimensions(from: source)

        let (filename, fileExtension) = extractFilenameAndExtension(from: filePath) ?? ("", "")
        return ImageMetadata(
            filename: filename,
            fileExtension: fileExtension,
            fileSize: fileSize,
            dimensions: dimensions ?? .zero,
            contentType: contentType
        )
    }
    
    /// Extracts filename and extension from a file path.
    /// - Parameter path: The file path string.
    /// - Returns: A tuple of (filename, fileExtension), or nil if extraction fails.
    private func extractFilenameAndExtension(
        from path: String
    ) -> (filename: String, fileExtension: String)? {
        let url = URL(fileURLWithPath: path)
        let filename = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension
        
        return fileExtension.isEmpty ? nil : (filename, fileExtension)
    }

    /// Loads image data from a file URL at the specified resolution.
    /// - Parameters:
    ///   - url: The file URL of the image.
    ///   - resolution: The desired resolution (full or thumbnail).
    /// - Returns: The image data.
    /// - Throws: ImageRepositoryError if the image cannot be loaded.
    func image(
        for url: URL,
        resolution: ImageResolution
    ) async throws -> ImageData {
        switch resolution {
        case .full:
            guard let imageData = createImage(from: url) else {
                throw ImageRepositoryError.dataCorrupted(atURL: url)
            }

            return imageData
        case .thumbnail:
            guard let imageData = createThumbnail(from: url, maxSize: 400) else {
                throw ImageRepositoryError.dataCorrupted(atURL: url)
            }

            return imageData
        }
    }
}

/// Retrieves image dimensions from a file URL using ImageIO.
/// - Parameter url: The file URL of the image.
/// - Returns: Image dimensions as CGSize, or nil if dimensions cannot be determined.
private func getImageDimensions(from url: URL) -> CGSize? {
    guard
        let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
        let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
        let width = properties[kCGImagePropertyPixelWidth as String] as? CGFloat,
        let height = properties[kCGImagePropertyPixelHeight as String] as? CGFloat
    else {
        return nil
    }

    return CGSize(width: width, height: height)
}

/// Creates image data by reading the file at the given URL.
/// - Parameter url: The file URL of the image.
/// - Returns: Image data, or nil if reading fails.
private func createImage(from url: URL) -> ImageData? {
    let didStartAccess = url.startAccessingSecurityScopedResource()
    defer {
        if didStartAccess {
            url.stopAccessingSecurityScopedResource()
        }
    }

    guard let imageData = try? Data(contentsOf: url) else {
        return nil
    }

    return imageData
}

/// Creates a thumbnail image from a file URL using ImageIO.
/// - Parameters:
///   - url: The file URL of the source image.
///   - maxSize: Maximum pixel dimension for the thumbnail.
///   - scale: Display scale factor. Defaults to current display scale.
/// - Returns: Thumbnail image data as PNG, or nil if creation fails.
private func createThumbnail(
    from url: URL,
    maxSize: CGFloat,
    scale: CGFloat = UITraitCollection.current.displayScale
) -> ImageData? {
    let didStartAccess = url.startAccessingSecurityScopedResource()
    defer {
        if didStartAccess {
            url.stopAccessingSecurityScopedResource()
        }
    }

    let options = [
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: Constants.thumbnailSize
    ] as CFDictionary

    let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
    let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options)!
    let thumbnail = UIImage(cgImage: imageReference)
    return thumbnail.pngData()
}
