import Observation
import Foundation

/// Service for retrieving image data and metadata using an image repository.
@Observable
final class ImageService: Sendable {
    private let imageRepository: ImageRepository

    /// Creates an ImageService with the provided repository.
    /// - Parameter imageRepository: The repository to use for image operations.
    init(imageRepository: ImageRepository) {
        self.imageRepository = imageRepository
    }

    // MARK: - Image Data

    /// Retrieves image data for a given URL at the specified resolution.
    /// - Parameters:
    ///   - url: The source URL of the image.
    ///   - resolution: The desired resolution (full or thumbnail).
    /// - Returns: The image data.
    /// - Throws: Errors if the image cannot be loaded.
    func imageData(
        for url: URL,
        resolution: ImageResolution
    ) async throws -> ImageData {
        try await imageRepository.image(
            for: url,
            resolution: resolution
        )
    }

    // MARK: - Image Metadata

    /// Retrieves metadata for an image at the given URL.
    /// - Parameter url: The source URL of the image.
    /// - Returns: Image metadata including dimensions, size, and format.
    /// - Throws: Errors if metadata cannot be retrieved.
    func metadata(
        for url: URL
    ) throws -> ImageMetadata {
        try imageRepository.metadata(for: url)
    }
}
