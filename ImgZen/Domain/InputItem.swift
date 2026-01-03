import Foundation

/// Represents an input item to be processed (e.g., for image conversion).
/// Can be sourced from a file URL or a handler that provides a file URL asynchronously.
struct InputItem: Identifiable {
    /// The underlying source type of the input item.
    enum Source {
        /// Input is directly provided as a file URL.
        case fileURL(URL)
        /// Input is provided asynchronously via a handler/callback supplying the file URL.
        case fileURLHandler(handler: (@Sendable @escaping (URL) -> Void) -> Void)
    }

    /// Unique identifier for this input item.
    let id = UUID()
    /// Source descriptor for how to retrieve the input's data.
    let source: Source
}

/// Conformance to Hashable for use in Swift collections.
extension InputItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension InputItem: Equatable {
    static func == (lhs: InputItem, rhs: InputItem) -> Bool {
        lhs.id == rhs.id
    }
}
