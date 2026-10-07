import SwiftUI

/// A gallery view displaying a grid of image cells with async loading support.
struct ImageGallery: View {
    /// Represents an item in the image gallery with async loading support.
    struct Item: Identifiable, Equatable {
        let id: String
        let imageInfo: @Sendable @concurrent () async throws -> (ImageMetadata, ImageData)
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
                    AsyncResourceView(
                        load: {
                            let (image, metadata) = try await Task.detached(
                                priority: .userInitiated
                            ) { @concurrent in
                                let (metadata, imageData) = try await item.imageInfo()
                                let image = UIImage(data: imageData)
                                return (image, metadata)
                            }.value
                            return (image, metadata)
                        },
                        notRequestedView: { load in
                            PlaceholderTile()
                                .onFirstAppear(perform: load)
                        },
                        loadingView: {
                            PlaceholderTile {
                                ProgressView()
                            }
                        },
                        failureView: { _, retry in
                            PlaceholderTile {
                                VStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                    Text(String(localized: "label.imageUnavailable"))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                    Button(String(localized: "button.tryAgain"), action: retry)
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                }
                                .padding(8)
                            }
                        },
                        successView: { (image: UIImage?, metadata: ImageMetadata) in
                            let presenter = ImageItemPresenter(metadata: metadata)
                            let cell = ImageCell(
                                title: presenter.title,
                                subtitle: presenter.subtitle,
                                badge: presenter.badge,
                                image: image.map(Image.init(uiImage:)),
                                contextActions: item.contextActions,
                                isSelected: item.isSelected
                            )

                            if let primaryAction = item.primaryAction {
                                Button(action: primaryAction) {
                                    cell
                                }
                                .buttonStyle(.plain)
                            } else {
                                cell
                            }
                        }
                    )
                }
            }
            .animation(.smooth, value: items)
            .padding(.horizontal)
        }
    }
}

/// A square tile in the style of a cell, shown until an image has loaded, so the grid keeps its shape.
private struct PlaceholderTile<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .aspectRatio(1.0, contentMode: .fit)
            .overlay { content }
    }
}

private extension PlaceholderTile where Content == SwiftUI.EmptyView {
    init() {
        self.init { SwiftUI.EmptyView() }
    }
}
