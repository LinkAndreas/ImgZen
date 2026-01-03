import SwiftUI

/// A wrapper view that provides fade-in animation for window content.
struct WindowContentView: View {
    let content: AnyView

    @State private var isAnimating = false

    var body: some View {
        content
            .opacity(isAnimating ? 1.0 : 0)
            .onAppear {
                withAnimation(.smooth(duration: 0.25)) {
                    isAnimating = true
                }
            }
    }
}
