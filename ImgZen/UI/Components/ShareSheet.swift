import SwiftUI

/// A SwiftUI wrapper for UIActivityViewController for sharing files.
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var activities: [UIActivity]? = nil
    /// Called when sharing finishes or is cancelled, since the controller then closes itself.
    var onComplete: @MainActor () -> Void = {}
    
    /// Creates and configures the UIActivityViewController.
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: activities
        )
        controller.completionWithItemsHandler = { _, _, _, _ in
            // UIKit calls this on the main thread.
            MainActor.assumeIsolated {
                onComplete()
            }
        }
        return controller
    }
    
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
