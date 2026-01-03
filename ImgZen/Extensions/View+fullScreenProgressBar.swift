import SwiftUI

/// Extension providing a full-screen progress bar overlay modifier.
extension View {
    /// Adds a full-screen progress bar overlay that appears when progress is provided.
    /// - Parameters:
    ///   - title: Title text displayed above the progress indicator.
    ///   - subtitle: Optional subtitle text.
    ///   - progress: Optional progress state. When nil, the overlay is hidden.
    ///   - onCancel: Action to perform when cancel is tapped.
    /// - Returns: A view with the progress bar overlay modifier applied.
    public func fullScreenProgressBar(
        title: String,
        subtitle: String? = nil,
        progress: ProgressBar.State? = nil,
        onCancel: @escaping () -> Void
    ) -> some View {
        self
            .overlay {
                if let progress  {
                    ProgressBar(
                        title: title,
                        subtitle: subtitle,
                        state: progress,
                        onCancel: onCancel
                    )
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: progress)
                }
            }
    }
}

#Preview {
    Color.clear
        .fullScreenProgressBar(
            title: "Image Conversion",
            subtitle: "Converting images…",
            progress: .indeterminate,
            onCancel: {}
        )
}
