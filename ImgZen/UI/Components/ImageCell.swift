import SwiftUI

/// A cell displaying an image with its format and metadata.
/// Selection, taps and context menus are handled by the gallery tile around it,
/// so they also work while the image is still loading.
struct ImageCell: View {
    private let title: String
    private let subtitle: String
    private let badge: String
    private let image: Image?

    /// Creates an image cell.
    /// - Parameters:
    ///   - title: Title text to display.
    ///   - subtitle: Subtitle text (typically dimensions and file size).
    ///   - badge: Badge text (typically format name).
    ///   - image: Optional SwiftUI Image to display.
    init(
        title: String,
        subtitle: String,
        badge: String,
        image: Image?
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.image = image
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .overlay {
                    if let image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .clipped()
                .overlay(alignment: .bottomTrailing) {
                    Badge(text: badge)
                        .padding(6)
                }

            Text(subtitle)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
                .fixedSize(horizontal: false, vertical: true)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue("\(badge), \(subtitle)")
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ImageCell(
        title: "Beach.heic",
        subtitle: "4032 x 3024 px · 22,4 MB",
        badge: "PNG",
        image: Image(systemName: "photo")
    )
    .frame(width: 200, height: 200)
}
