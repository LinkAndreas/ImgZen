import SwiftUI
import UIKit

/// A gallery view displaying a grid of image cells with async loading support.
struct ImageGallery: View {
    /// Represents an item in the image gallery with async loading support.
    struct Item: Identifiable, Equatable {
        let id: String
        /// Loads the item's preview off the main actor.
        let loadPreview: @Sendable @concurrent () async throws -> ImagePreview
        /// Returns the item's preview if it's already in memory, so the cell can show it without a spinner.
        let cachedPreview: @Sendable () -> ImagePreview?
        let contextActions: [ContextAction]
        /// Action performed when the item is tapped, if any.
        var primaryAction: (() -> Void)? = nil
        /// The selection state, or nil if the item isn't selectable.
        var isSelected: Bool? = nil

        static func ==(lhs: Self, rhs: Self) -> Bool {
            // SwiftUI skips redrawing the gallery when its items compare equal, so include everything displayed.
            return lhs.id == rhs.id && lhs.isSelected == rhs.isSelected
        }
    }

    /// Adaptive columns reflow continuously as the window resizes (e.g. folding or unfolding iPhone Duo).
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]

    private var items: [Item]

    /// Creates an image gallery.
    /// - Parameter items: The items to display in the gallery.
    init(items: [Item]) {
        self.items = items
    }
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(
                columns: columns,
                spacing: 12
            ) {
                ForEach(items) { item in
                    GalleryTile(item: item)
                }
            }
            .animation(.smooth, value: items)
        }
        // Margins add to the safe area insets (bars, the iPhone Duo vertical bar, the sensor housing in landscape),
        // so the first and last rows keep their spacing instead of touching the bars.
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .contentMargins(.vertical, 12, for: .scrollContent)
        // Content that fits on screen doesn't bounce, so an empty or short gallery doesn't drag the bars around.
        .scrollBounceBehavior(.basedOnSize)
        // The grouped background goes on the navigation container rather than the scroll view,
        // so it doesn't interfere with the navigation bar's scroll edge effect.
        .containerBackground(Color(.systemGroupedBackground), for: .navigation)
    }
}

/// One square tile of the gallery: loads its preview, and handles taps, selection and the context menu.
///
/// Built for smooth scrolling: a tile that scrolls back into view shows its cached preview at once,
/// and loading is a `task` that's cancelled when the tile scrolls away, so fast scrolling
/// doesn't queue up work for cells that are long gone. Selection is drawn here rather than
/// in the loaded content, so it updates immediately, even while the image is loading.
private struct GalleryTile: View {
    let item: ImageGallery.Item

    @State private var preview: ImagePreview?
    @State private var didFail = false
    /// Increased to load again after a failure.
    @State private var attempt = 0

    private static let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

    init(item: ImageGallery.Item) {
        self.item = item
        _preview = State(initialValue: item.cachedPreview())
    }

    var body: some View {
        Group {
            if let primaryAction = item.primaryAction {
                Button(action: primaryAction) {
                    content
                }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
        .contentShape(.hoverEffect, Self.shape)
        .hoverEffect(.lift)
        .contextMenu {
            ForEach(item.contextActions) { action in
                Button(role: action.destructive ? .destructive : nil) {
                    action.execute()
                } label: {
                    Label(action.title, systemImage: action.systemImage)
                }
            }
        }
        .accessibilityAddTraits(item.isSelected == true ? .isSelected : [])
        .task(id: attempt) {
            guard preview == nil else { return }

            do {
                preview = try await item.loadPreview()
            } catch {
                // A tile that scrolled away was cancelled, not failed; it loads again when it reappears.
                if !Task.isCancelled {
                    didFail = true
                }
            }
        }
    }

    private var content: some View {
        Group {
            if let preview {
                let presenter = ImageItemPresenter(metadata: preview.metadata)
                ImageCell(
                    title: presenter.title,
                    subtitle: presenter.subtitle,
                    badge: presenter.badge,
                    image: preview.thumbnail
                )
            } else if didFail {
                PlaceholderTile {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text(String(localized: "label.imageUnavailable"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button(String(localized: "button.tryAgain")) {
                            didFail = false
                            attempt += 1
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(8)
                }
            } else {
                PlaceholderTile {
                    ProgressView()
                }
            }
        }
        .aspectRatio(1.0, contentMode: .fit)
        .clipShape(Self.shape)
        .overlay {
            // Unselected images are washed out with a plain overlay, which is cheaper to draw while
            // scrolling than lowering the opacity of the whole cell.
            if item.isSelected == false {
                Self.shape.fill(Color(.systemBackground).opacity(0.4))
            }
        }
        .overlay {
            Self.shape.strokeBorder(
                item.isSelected == true ? Color.accentColor : Color.secondary.opacity(0.2),
                lineWidth: item.isSelected == true ? 3 : 0.5
            )
        }
        .overlay(alignment: .topTrailing) {
            if let isSelected = item.isSelected {
                SelectionIndicator(isSelected: isSelected)
                    .padding(8)
            }
        }
        .animation(.smooth(duration: 0.15), value: item.isSelected)
        .contentShape(Self.shape)
    }
}

/// The checkmark badge showing whether an image is selected.
private struct SelectionIndicator: View {
    let isSelected: Bool

    var body: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title2)
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, isSelected ? Color.accentColor : Color.black.opacity(0.3))
            .background(Circle().fill(isSelected ? Color.white : Color.black.opacity(0.2)).padding(2))
            .contentTransition(.symbolEffect(.replace))
            .accessibilityHidden(true)
    }
}

/// A square tile in the style of a cell, shown until an image has loaded, so the grid keeps its shape.
private struct PlaceholderTile<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Rectangle()
            .fill(Color(.secondarySystemGroupedBackground))
            .overlay { content }
    }
}
