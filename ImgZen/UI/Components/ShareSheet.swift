import SwiftUI

/// A SwiftUI wrapper for UIActivityViewController for sharing files.
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var activities: [UIActivity]? = nil
    
    /// Creates and configures the UIActivityViewController.
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: activities
        )
        return controller
    }
    
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
