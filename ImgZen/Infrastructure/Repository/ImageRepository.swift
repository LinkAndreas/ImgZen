import Foundation

/// Errors that can occur when accessing image repositories.
enum ImageRepositoryError: Swift.Error {
    case itemNotFound(atURL: URL)
    case dataCorrupted(atURL: URL)
}

/// Protocol defining the interface for retrieving image data and metadata.
protocol ImageRepository {
    /// Retrieves metadata for an image at the given URL.
    /// - Parameter url: The source URL of the image.
    /// - Returns: Image metadata including dimensions, size, and format.
    /// - Throws: ImageRepositoryError if metadata cannot be retrieved.
    func metadata(
        for url: URL
    ) throws -> ImageMetadata

    /// Retrieves image data for a given URL at the specified resolution.
    /// - Parameters:
    ///   - url: The source URL of the image.
    ///   - resolution: The desired resolution (full or thumbnail).
    /// - Returns: The image data.
    /// - Throws: ImageRepositoryError if the image cannot be loaded.
    func image(
        for url: URL,
        resolution: ImageResolution
    ) async throws -> ImageData
}
