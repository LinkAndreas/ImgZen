import Foundation
import OSLog

/// Service that orchestrates image conversion from input items to a target format.
/// Emits events during conversion for progress tracking.
@Observable
final class ImageConversionService {
    /// Events emitted during the conversion process.
    enum Event {
        /// Conversion has started.
        case started
        /// Conversion progress update with completed and total counts.
        case converting(completed: Int, total: Int)
        /// Conversion completed with all output items.
        case completed([OutputItem])
    }

    typealias FileName = String

    private let metadata: @concurrent (ImageSource) async throws -> ImageMetadata
    private let imageData: @concurrent (ImageSource, ImageResolution) async throws -> ImageData
    private let fileURLFor: @concurrent (InputItem) async throws -> URL
    private let prepareOutputDirectory: () throws -> Void
    private let writeData: @concurrent (Data, FileName) async throws -> URL
    private let convert: @concurrent (
        _ imageData: Data,
        _ targetFormat: ImageFormat
    ) async -> ImageData?

    /// Creates an ImageConversionService with dependency injection.
    /// - Parameters:
    ///   - metadata: Closure to retrieve image metadata from a source URL.
    ///   - imageData: Closure to retrieve image data at a given resolution.
    ///   - fileURLFor: Closure to resolve file URL from an InputItem.
    ///   - prepareOutputDirectory: Closure to prepare the output directory.
    ///   - writeData: Closure to write data to a file and return its URL.
    ///   - convert: Closure to convert image data to a target format.
    init(
        metadata: @concurrent @escaping (ImageSource) async throws -> ImageMetadata,
        imageData: @concurrent @escaping (ImageSource, ImageResolution) async throws -> ImageData,
        fileURLFor: @escaping @MainActor (InputItem) async throws -> URL,
        prepareOutputDirectory: @escaping () throws -> Void,
        writeData: @concurrent @escaping (Data, FileName) async throws -> URL,
        convert: @concurrent @escaping (
            _ imageData: Data,
            _ targetFormat: ImageFormat
        ) async -> ImageData?
    ) {
        self.metadata = metadata
        self.imageData = imageData
        self.fileURLFor = fileURLFor
        self.prepareOutputDirectory = prepareOutputDirectory
        self.writeData = writeData
        self.convert = convert
    }
    
    /// Converts a list of input items to the specified image format.
    /// Items that fail to load or convert are skipped, so the stream always completes unless it is cancelled.
    /// - Parameters:
    ///   - items: The input items to convert.
    ///   - imageFormat: The target format for conversion.
    /// - Returns: An AsyncStream that emits conversion events. Cancelling its consumer stops the conversion.
    /// - Throws: Errors if output directory preparation fails.
    func convert(
        items: [InputItem],
        imageFormat: ImageFormat,
    ) throws -> AsyncStream<Event> {
        try prepareOutputDirectory()
        return AsyncStream { continuation in
            let task = Task {
                continuation.yield(.started)

                var result: [OutputItem] = []
                var usedFilenames: Set<FileName> = []
                var completed = 0
                let total = items.count

                for item in items {
                    guard !Task.isCancelled else { break }

                    do {
                        let url = try await fileURLFor(item)
                        let metadata = try await metadata(url)
                        let inputData = try await imageData(url, .full)
                        if let outputData = await convert(inputData, imageFormat) {
                            let filename = Self.uniqueFilename(
                                baseName: metadata.filename,
                                fileExtension: imageFormat.fileExtension,
                                usedFilenames: &usedFilenames
                            )
                            let url = try await writeData(outputData, filename)
                            result += [OutputItem(url: url)]
                        }
                    } catch {
                        logger.error("Failed to convert item \(item.id): \(error)")
                    }

                    completed += 1
                    continuation.yield(.converting(completed: completed, total: total))
                }

                if !Task.isCancelled {
                    continuation.yield(.completed(result))
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Returns a filename that has not been used yet in this conversion, appending a counter if needed
    /// (e.g. `IMG_0001.jpg`, `IMG_0001 2.jpg`), so inputs with the same name don't overwrite each other.
    static func uniqueFilename(
        baseName: String,
        fileExtension: String,
        usedFilenames: inout Set<FileName>
    ) -> FileName {
        let baseName = baseName.isEmpty ? "image" : baseName
        var filename = "\(baseName).\(fileExtension)"
        var counter = 2

        while usedFilenames.contains(filename.lowercased()) {
            filename = "\(baseName) \(counter).\(fileExtension)"
            counter += 1
        }

        usedFilenames.insert(filename.lowercased())
        return filename
    }
}
