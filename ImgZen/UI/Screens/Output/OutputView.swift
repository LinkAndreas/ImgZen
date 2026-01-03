import SwiftUI

/// The output screen displaying converted images ready for sharing.
struct OutputView: View {
    /// Represents items to be shared via the share sheet.
    struct ShareItem: Identifiable {
        let id = UUID()
        let fileURLs: [URL]
        
        /// Creates a ShareItem with a single file URL.
        /// - Parameter fileURL: The file URL to share.
        init(fileURL: URL) {
            self.fileURLs = [fileURL]
        }
        
        /// Creates a ShareItem with multiple file URLs.
        /// - Parameter fileURLs: The file URLs to share.
        init(fileURLs: [URL]) {
            self.fileURLs = fileURLs
        }
    }
    
    @State private var shareItem: ShareItem?
    
    private let items: [OutputItem]
    private let imageData: @Sendable @concurrent (ImageSource, ImageResolution) async throws -> ImageData
    private let metadata: @Sendable @concurrent (ImageSource) async throws -> ImageMetadata
    
    /// Creates an OutputView.
    /// - Parameters:
    ///   - items: The output items to display.
    ///   - imageData: Closure to retrieve image data at a given resolution.
    ///   - metadata: Closure to retrieve image metadata.
    init(
        items: [OutputItem],
        imageData: @Sendable @concurrent @escaping (ImageSource, ImageResolution) async throws -> ImageData,
        metadata: @Sendable @concurrent @escaping (ImageSource) async throws -> ImageMetadata
    ) {
        self.items = items
        self.imageData = imageData
        self.metadata = metadata
    }

    var body: some View {
        ImageGallery(
            items: items.map { item in
                ImageGallery.Item(
                    id: item.id.uuidString,
                    imageInfo: { @concurrent in
                        let metadata = try await metadata(item.url)
                        let imageData = try await imageData(item.url, .thumbnail)
                        return (metadata, imageData)
                    },
                    contextActions: [
                        ContextAction(
                            title: String(localized: "button.share"),
                            systemImage: "square.and.arrow.up",
                            destructive: false,
                            execute: { share(item: item) }
                        )
                    ]
                )
            }
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(
                    "",
                    systemImage: "square.and.arrow.up",
                    action: shareAll
                )
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: item.fileURLs)
        }
        .navigationTitle(String(localized: "navigation.readyToShare"))
    }
    
    /// Presents share sheet for a single output item.
    /// - Parameter item: The output item to share.
    private func share(item: OutputItem) {
        shareItem = ShareItem(fileURL: item.url)
    }
    
    /// Presents share sheet for all output items.
    private func shareAll() {
        let fileURLs: [URL] = items.map(\.url)
        shareItem = ShareItem(fileURLs: fileURLs)
    }
}
