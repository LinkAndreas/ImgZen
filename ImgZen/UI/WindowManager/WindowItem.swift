import SwiftUI
import Foundation

/// Represents a window item with content and optional dismiss callback.
struct WindowItem: Identifiable {
    let id = UUID()
    let content: AnyView
    let onDismiss: (() -> Void)?

    /// Creates a WindowItem.
    /// - Parameters:
    ///   - content: The SwiftUI view content to display.
    ///   - onDismiss: Optional callback when the window is dismissed.
    init<Content: View>(
        content: Content,
        onDismiss: (() -> Void)? = nil
    ) {
        self.content = AnyView(content)
        self.onDismiss = onDismiss
    }
}