import SwiftUI

/// A styled badge component for displaying text labels with a capsule background.
struct Badge: View {
    let text: String

    /// Creates a badge with the given text.
    /// - Parameter text: The text to display in the badge.
    init(text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            // A plain fill instead of a blur: every cell shows a badge, and a blur per cell
            // is expensive to redraw while scrolling.
            .background(.black.opacity(0.55), in: .capsule)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    Badge(text: "PNG")
        .frame(width: 400, height: 400)
}
