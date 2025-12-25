import Foundation

/// Service for managing file storage operations, including writing data and preparing directories.
final class StorageService {

    // MARK: - Properties

    private let fileManager: FileManager
    private let baseDirectory: URL
    private let subdirectoryName: String

    /// The computed destination directory path combining base directory and subdirectory.
    private var destinationDirectory: URL {
        baseDirectory.appendingPathComponent(subdirectoryName, isDirectory: true)
    }

    // MARK: - Init

    /// Creates a StorageService.
    /// - Parameters:
    ///   - baseDirectory: The base directory for storage operations.
    ///   - subdirectoryName: The subdirectory name within the base directory.
    ///   - fileManager: FileManager instance to use. Defaults to `.default`.
    init(
        baseDirectory: URL,
        subdirectoryName: String,
        fileManager: FileManager = .default
    ) {
        self.baseDirectory = baseDirectory
        self.subdirectoryName = subdirectoryName
        self.fileManager = fileManager
    }

    // MARK: - Public API
    
    /// Writes data to a file inside the destination directory.
    /// - Parameters:
    ///   - data: The data to write.
    ///   - filename: The filename to use.
    /// - Returns: The URL of the written file.
    /// - Throws: File system errors if writing fails.
    @discardableResult
    func write(_ data: Data, filename: String) throws -> URL {
        let fileURL = destinationDirectory.appendingPathComponent(filename)
        try data.write(to: fileURL, options: [.atomic])
        return fileURL
    }

    // MARK: - Private Helpers

    /// Ensures the destination directory exists and is empty.
    /// If the directory exists, its contents are removed. If it doesn't exist, it is created.
    /// - Throws: File system errors if directory operations fail.
    func prepareDirectory() throws {
        if fileManager.fileExists(atPath: destinationDirectory.path) {
            // Clean out directory contents
            let contents = try fileManager.contentsOfDirectory(
                at: destinationDirectory,
                includingPropertiesForKeys: nil
            )

            for url in contents {
                try fileManager.removeItem(at: url)
            }
        } else {
            // Directory does not exist → create it
            try fileManager.createDirectory(
                at: destinationDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}
