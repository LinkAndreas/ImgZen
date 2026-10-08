import SwiftUI

/// The output screen displaying converted images ready for sharing.
struct OutputView: View {
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
                    contextActions: [],
                    shareURL: item.url,
                    primaryAction: { toggleSelection(of: item) },
                    isSelected: selectedItemIDs.contains(item.id)
                )
            }
        )
        // Real toolbar items rather than a custom bar, so they move into the vertical bar on iPhone Duo.
        // Selecting and sharing are the main actions here, so they sit together within reach of the right thumb.
        .toolbarPreferringVerticalBar {
            ToolbarSpacer(.flexible, placement: .bottomBar)

            ToolbarItem(placement: .bottomBar) {
                Button(action: toggleSelectAll) {
                    VerticalBarReader { isVertical in
                        if isVertical {
                            Label(
                                String(localized: areAllItemsSelected ? "button.deselectAll" : "button.selectAll"),
                                systemImage: areAllItemsSelected ? "checkmark.circle.fill" : "checkmark.circle"
                            )
                            .labelStyle(.iconOnly)
                        } else {
                            // Sized for the longer of both titles, so the bar doesn't shift when it switches.
                            ZStack {
                                Text(String(localized: "button.selectAll")).hidden()
                                Text(String(localized: "button.deselectAll")).hidden()
                                Text(String(localized: areAllItemsSelected ? "button.deselectAll" : "button.selectAll"))
                            }
                            // Room around the title, so the button doesn't look squeezed next to Share.
                            .padding(.horizontal, 8)
                        }
                    }
                }
            }

            ToolbarItem(placement: .bottomBar) {
                // ShareLink presents the system share sheet, anchored to the button as a popover on iPad.
                ShareLink(items: selectedFileURLs) {
                    VerticalBarReader { isVertical in
                        let title = String(format: String(localized: "button.shareCount"), selectedItemIDs.count)
                        if isVertical {
                            Label(title, systemImage: "square.and.arrow.up")
                                .labelStyle(.iconOnly)
                        } else {
                            // Icon and title as separate views: toolbars show a Label as its icon only,
                            // but sharing is the main action here, so its title stays visible.
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text(title)
                                    .monospacedDigit()
                            }
                            .padding(.horizontal, 8)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(title)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(selectedItemIDs.isEmpty)
            }
        }
        .sensoryFeedback(.selection, trigger: selectedItemIDs)
        .navigationTitle(String(localized: "navigation.readyToShare"))
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
