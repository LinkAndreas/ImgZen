import SwiftUI

/// A gallery view displaying a grid of image cells with async loading support.
struct ImageGallery: View {
    /// Represents an item in the image gallery with async loading support.
    struct Item: Identifiable, Equatable {
        let id: String
        let imageInfo: @Sendable @concurrent () async throws -> (ImageMetadata, ImageData)
        let contextActions: [ContextAction]

        static func ==(lhs: Self, rhs: Self) -> Bool {
            return lhs.id == rhs.id
        }
    }

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass: UserInterfaceSizeClass?

    private var columns: [GridItem] {
        switch horizontalSizeClass {
        case .regular:
            return [
                GridItem(.adaptive(minimum: 180), spacing: 12)
            ]
        default:
            return [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
    }

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
                        loadingView: {
                            ZStack {
                                Color.clear
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .controlSize(.large)
                            }
                            .aspectRatio(1.0, contentMode: .fit)
                        },
                        successView: { (image: UIImage?, metadata: ImageMetadata) in
                            let presenter = ImageItemPresenter(metadata: metadata)
                            ImageCell(
                                title: presenter.title,
                                subtitle: presenter.subtitle,
                                badge: presenter.badge,
                                image: image.map(Image.init(uiImage:)),
                                contextActions: item.contextActions
                            )
                        }
                    )
                }
            }
            .animation(.smooth, value: items)
            .padding(.horizontal)
        }
    }
}
