import Foundation

/// Represents an output file produced by image processing/conversion.
struct OutputItem: Identifiable, Hashable, Sendable {
    /// Unique identifier (UUID) for the output item.
    let id: UUID
    /// The file URL where the output is written.
    let url: URL

    /// Initializes a new OutputItem.
    /// - Parameters:
    ///   - id: Optionally override the UUID.
    ///   - url: Output file URL.
    init(
        id: UUID = UUID(),
        url: URL
    ) {
        self.id = id
        self.url = url
    }
}
