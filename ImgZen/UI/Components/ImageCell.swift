import SwiftUI

/// A cell component for displaying an image with metadata and context menu actions.
struct ImageCell: View {    
    private let title: String
    private let subtitle: String
    private let badge: String
    private let image: Image?
    private let contextActions: [ContextAction]

    /// Creates an image cell.
    /// - Parameters:
    ///   - title: Title text to display.
    ///   - subtitle: Subtitle text (typically dimensions and file size).
    ///   - badge: Badge text (typically format name).
    ///   - image: Optional SwiftUI Image to display.
    ///   - contextActions: Actions available in the context menu.
    init(
        title: String,
        subtitle: String,
        badge: String,
        image: Image?,
        contextActions: [ContextAction] = []
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.image = image
        self.contextActions = contextActions
    }

    var body: some View {
        ZStack {
            Color(.secondarySystemGroupedBackground)
            VStack(spacing: 0) {
                ZStack {
                    GeometryReader { geometry in
                        if let image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        } else {
                            Color.clear
                        }
                    }
                    Badge(text: badge)
                        .padding(6)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .bottomTrailing
                        )
                }
                VStack(alignment: .leading) {
                    Text(subtitle)
                        .lineLimit(2)
                        .font(.caption)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
        )
        .shadow(
            color: .black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .stroke(
                Color.secondary.opacity(0.2),
                lineWidth: 0.5
            )
        )
        .aspectRatio(1.0, contentMode: .fit)
        .contextMenu {
            ForEach(contextActions) { action in
                Button(role: action.destructive ? .destructive : .confirm) {
                    action.execute()
                } label: {
                    Label(action.title, systemImage: action.systemImage)
                }
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ZStack {
        ImageCell(
            title: "Beach.heic",
            subtitle: "4032 x 3024 px · 22,4 MB",
            badge: "PNG",
            image: Image(systemName: ""),
            contextActions: []
        )
        .frame(width: 200, height: 200)
    }
    .frame(width: 300, height: 300)
}
