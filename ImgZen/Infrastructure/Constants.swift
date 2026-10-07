import Foundation

/// App-wide constants and configuration values.
enum Constants {
    /// Maximum pixel size for generated thumbnails.
    static let thumbnailSize: CGFloat = 800
    /// Directory that picked photos are copied into while they're being converted.
    static let inputCacheDirectory: URL = .cachesDirectory.appending(path: "input", directoryHint: .isDirectory)
    /// Directory containing a folder of converted images per window.
    static let outputDirectory: URL = .applicationSupportDirectory.appending(path: "output", directoryHint: .isDirectory)
}
