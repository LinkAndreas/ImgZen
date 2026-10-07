import Foundation

/// Resolves file URLs from InputItems, handling both direct URLs and async handler-based sources.
final class FileURLResolver {
    private let fileManager: FileManager
    private let cacheDirectory: URL
    /// Resolutions per input item, so concurrent requests (thumbnail and conversion) share one copy of the file.
    private var resolutions: [InputItem.ID: Task<URL, Error>] = [:]

    /// Creates a FileURLResolver.
    /// - Parameters:
    ///   - cacheDirectory: Directory that handler-based sources are copied into.
    ///   - fileManager: FileManager instance to use. Defaults to `.default`.
    init(
        cacheDirectory: URL = Constants.inputCacheDirectory,
        fileManager: FileManager = .default
    ) {
        self.cacheDirectory = cacheDirectory
        self.fileManager = fileManager
    }

    /// Resolves a file URL for the given InputItem.
    /// For handler-based sources, copies the file into a per-item folder of the cache directory.
    /// - Parameter item: The input item to resolve.
    /// - Returns: A file URL that can be used to access the file.
    /// - Throws: Errors reported by the source, or file system errors if file operations fail.
    func fileURL(for item: InputItem) async throws -> URL {
        switch item.source {
        case let .fileURL(url):
            return url
        case let .fileURLHandler(handler):
            if let resolution = resolutions[item.id] {
                return try await resolution.value
            }

            // FileManager's file operations are thread-safe; the handler calls back on a background queue.
            nonisolated(unsafe) let fileManager = fileManager
            let destinationDirectoryURL = cacheDirectory.appending(path: item.id.uuidString, directoryHint: .isDirectory)
            let resolution = Task {
                try await withCheckedThrowingContinuation { continuation in
                    handler { result in
                        // The provided file is deleted once the handler returns, so copy it synchronously.
                        do {
                            let url = try result.get()
                            let destinationURL = destinationDirectoryURL.appendingPathComponent(url.lastPathComponent)

                            try fileManager.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)

                            if fileManager.fileExists(atPath: destinationURL.path) {
                                try fileManager.removeItem(at: destinationURL)
                            }

                            try fileManager.copyItem(at: url, to: destinationURL)
                            continuation.resume(returning: destinationURL)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
            resolutions[item.id] = resolution

            do {
                return try await resolution.value
            } catch {
                // Allow a later retry instead of caching the failure.
                resolutions[item.id] = nil
                throw error
            }
        }
    }
}
