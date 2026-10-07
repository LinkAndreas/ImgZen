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
    /// Images to share; all of them are selected initially.
    @State private var selectedItemIDs: Set<OutputItem.ID>

    private var areAllItemsSelected: Bool {
        selectedItemIDs.count == items.count
    }
    
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
        self._selectedItemIDs = State(initialValue: Set(items.map(\.id)))
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
                    ],
                    primaryAction: { toggleSelection(of: item) },
                    isSelected: selectedItemIDs.contains(item.id)
                )
            }
        )
        .safeAreaBar(edge: .bottom) {
            // Selecting and sharing are the main actions here, so they sit within thumb reach.
            HStack(spacing: 12) {
                Button(
                    String(localized: areAllItemsSelected ? "button.deselectAll" : "button.selectAll"),
                    action: toggleSelectAll
                )
                .buttonStyle(.glass)
                .controlSize(.large)

                Button(action: shareSelectedItems) {
                    Label(
                        String(format: String(localized: "button.shareCount"), selectedItemIDs.count),
                        systemImage: "square.and.arrow.up"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .disabled(selectedItemIDs.isEmpty)
            }
            .frame(maxWidth: 560)
            .padding(20)
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: item.fileURLs)
                .presentationDetents([.medium, .large])
        }
        .navigationTitle(String(localized: "navigation.readyToShare"))
    }
    
    /// Presents share sheet for a single output item.
    /// - Parameter item: The output item to share.
    private func share(item: OutputItem) {
        shareItem = ShareItem(fileURL: item.url)
    }
    
    /// Selects or deselects an output item for sharing.
    /// - Parameter item: The output item to toggle.
    private func toggleSelection(of item: OutputItem) {
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    /// Selects all output items, or deselects them if all are selected.
    private func toggleSelectAll() {
        selectedItemIDs = areAllItemsSelected ? [] : Set(items.map(\.id))
    }

    /// Presents share sheet for the selected output items.
    private func shareSelectedItems() {
        let fileURLs = items
            .filter { selectedItemIDs.contains($0.id) }
            .map(\.url)
        shareItem = ShareItem(fileURLs: fileURLs)
    }
}
