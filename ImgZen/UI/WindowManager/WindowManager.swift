import UIKit
import SwiftUI

/// Manages presentation of overlay windows with queuing support for multiple windows.
@Observable
@MainActor
final class WindowManager {
    static let shared = WindowManager()

    private(set) var windowQueue: [WindowItem] = []
    private(set) var currentWindow: WindowItem?

    private var currentUIWindow: UIWindow?
    private let baseWindowLevel: UIWindow.Level = .alert

    private init() {}

    /// Presents a new window with the given content.
    /// If a window is already showing, the new window is queued.
    /// - Parameters:
    ///   - content: The SwiftUI view content to display.
    ///   - onDismiss: Optional callback when the window is dismissed.
    func present<Content: View>(_ content: Content, onDismiss: (() -> Void)? = nil) {
        let window = WindowItem(content: content, onDismiss: onDismiss)

        if currentWindow == nil {
            // No window is currently shown, display immediately
            showWindow(window)
        } else {
            // Add to queue
            windowQueue.append(window)
        }
    }

    /// Dismisses the current window and shows the next one in queue if available.
    func dismiss() {
        // Call onDismiss callback
        currentWindow?.onDismiss?()

        // Hide and cleanup current window
        hideCurrentWindow()

        if windowQueue.isEmpty {
            // No more windows in queue
            currentWindow = nil
        } else {
            // Show next window from queue
            let nextWindow = windowQueue.removeFirst()
            showWindow(nextWindow)
        }
    }

    /// Dismiss all windows including queued ones
    func dismissAll() {
        currentWindow?.onDismiss?()
        windowQueue.forEach { $0.onDismiss?() }

        hideCurrentWindow()
        currentWindow = nil
        windowQueue.removeAll()
    }

    /// Get the number of windows in queue (not including current)
    var queueCount: Int {
        windowQueue.count
    }

    /// Check if any window is being displayed
    var isPresenting: Bool {
        currentWindow != nil
    }

    // MARK: - Private Methods

    /// Shows a window by creating a UIWindow and hosting the SwiftUI content.
    /// - Parameter window: The window item to display.
    private func showWindow(_ window: WindowItem) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }

        // Create UIWindow
        let uiWindow = PassThroughWindow(windowScene: scene)
        uiWindow.windowLevel = baseWindowLevel
        uiWindow.backgroundColor = .clear

        // Create hosting controller with the content
        let hostingController = UIHostingController(
            rootView: WindowContentView(
                content: window.content
            )
        )

        hostingController.view.backgroundColor = .clear
        uiWindow.rootViewController = hostingController
        uiWindow.isHidden = false

        // Store references
        currentUIWindow = uiWindow
        currentWindow = window

        // Animate appearance
        uiWindow.alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            uiWindow.alpha = 1
        }
    }

    /// Hides and cleans up the currently displayed window with animation.
    private func hideCurrentWindow() {
        guard let window = currentUIWindow else { return }

        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseIn
        ) {
            window.alpha = 0
        } completion: { _ in
            window.isHidden = true
            window.rootViewController = nil
        }

        currentUIWindow = nil
    }
}
