import Foundation

/// Resolves file URLs from InputItems, handling both direct URLs and async handler-based sources.
final class FileURLResolver {
    private let fileManager: FileManager

    /// Creates a FileURLResolver.
    /// - Parameter fileManager: FileManager instance to use. Defaults to `.default`.
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Resolves a file URL for the given InputItem.
    /// For handler-based sources, copies the file to app support directory.
    /// - Parameter item: The input item to resolve.
    /// - Returns: A file URL that can be used to access the file.
    /// - Throws: File system errors if file operations fail.
    func fileURL(for item: InputItem) async throws -> URL {
        switch item.source {
        case let .fileURL(url):
            return url
        case let .fileURLHandler(handler):
            return try await withCheckedThrowingContinuation { [weak self] continuation in
                handler { [weak self] url in
                    DispatchQueue.main.sync { [weak self] in
                        guard let self else { return }

                        do {
                            let filename = url.lastPathComponent
                            let destinationDirectoryURL = URL.applicationSupportDirectory.appendingPathComponent("input")
                            let destinationURL = destinationDirectoryURL.appendingPathComponent(filename)

                            if !self.fileManager.fileExists(atPath: destinationDirectoryURL.path) {
                                try? self.fileManager.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true)
                            }

                            if self.fileManager.fileExists(atPath: destinationURL.path) {
                                try self.fileManager.removeItem(at: destinationURL)
                            }

                            try self.fileManager.copyItem(at: url, to: destinationURL)
                            continuation.resume(returning: destinationURL)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
}
