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
    }
    
    @State private var shareItem: ShareItem?
    /// Images to share; all of them are selected initially.
    @State private var selectedItemIDs: Set<OutputItem.ID>

    private var areAllItemsSelected: Bool {
        selectedItemIDs.count == items.count
    }
    
    private let items: [OutputItem]
    private let previewLoader: ImagePreviewLoader
    
    /// Creates an OutputView.
    /// - Parameters:
    ///   - items: The output items to display.
    ///   - previewLoader: Loads the previews shown in the gallery.
    init(
        items: [OutputItem],
        previewLoader: ImagePreviewLoader
    ) {
        self.items = items
        self._selectedItemIDs = State(initialValue: Set(items.map(\.id)))
        self.previewLoader = previewLoader
    }

    var body: some View {
        ImageGallery(
            items: items.map { item in
                ImageGallery.Item(
                    id: item.id.uuidString,
                    loadPreview: { @concurrent [previewLoader] in
                        try await previewLoader.preview(for: item.url, cacheKey: item.id.uuidString)
                    },
                    cachedPreview: { [previewLoader] in
                        previewLoader.cachedPreview(forKey: item.id.uuidString)
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
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: toggleSelectAll) {
                        // Sized for the longer of both titles, so the share button doesn't resize when it switches.
                        ZStack {
                            Text(String(localized: "button.selectAll")).hidden()
                            Text(String(localized: "button.deselectAll")).hidden()
                            Text(String(localized: areAllItemsSelected ? "button.deselectAll" : "button.selectAll"))
                        }
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)

                    // ShareLink presents the system share sheet, anchored to the button as a popover on iPad.
                    ShareLink(items: selectedFileURLs) {
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
            }
            // Same spacing as the bottom bar of the input screen.
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: 560)
        }
        .sensoryFeedback(.selection, trigger: selectedItemIDs)
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

    /// The files of the selected output items, in gallery order.
    private var selectedFileURLs: [URL] {
        items
            .filter { selectedItemIDs.contains($0.id) }
            .map(\.url)
    }
}
