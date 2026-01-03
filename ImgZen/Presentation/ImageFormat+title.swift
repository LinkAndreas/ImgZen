import Foundation

/// Extension providing title strings for FormatSelection.
extension FormatSelection {
    /// A user-friendly title for the selected format.
    var title: String {
        switch self {
        case let .lossless(format):
            return format.title
        case let .lossy(format):
            return format.title
        }
    }
}
