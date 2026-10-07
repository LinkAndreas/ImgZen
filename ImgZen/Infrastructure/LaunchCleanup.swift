import Foundation

/// Removes files left over by previous app launches.
enum LaunchCleanup {
    /// Copied input files and converted output files are only used while the app runs,
    /// so they are removed once per launch rather than per window.
    static func removeLeftovers(fileManager: FileManager = .default) {
        let directories: [URL] = [
            Constants.inputCacheDirectory,
            Constants.outputDirectory,
            // Picked photos were copied here before 1.1.0.
            .applicationSupportDirectory.appending(path: "input", directoryHint: .isDirectory)
        ]

        for directory in directories {
            try? fileManager.removeItem(at: directory)
        }
    }
}
