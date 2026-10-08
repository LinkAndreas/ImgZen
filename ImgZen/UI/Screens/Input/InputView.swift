import OSLog
import UniformTypeIdentifiers
import SwiftUI
import PhotosUI
import UIKit

/// The main input screen where users select images and configure conversion settings.
struct InputView: View {
    /// Enum representing sheet types that can be presented.
    enum Sheet {
        /// Photo picker sheet for selecting from photo library.
        case photoPicker
        /// File picker sheet for selecting from files.
        case filePicker
    }

    @State private var isStartOverConfirmationShown: Bool = false
    @State private var sheet: Sheet?
    @State private var selectedImageFormat: FormatSelection = .lossy(.jpeg)
    @State private var selectedImageCompressionQuality: ImageCompressionQuality = 0.9
    @State private var inputService = InputService()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isDropTargeted = false
    @State private var isFormatSheetPresented = false
    /// Whether the bars are vertical (iPhone Duo), where the format sheet opens at full height.
    @State private var usesVerticalBars = false
    /// The size of the screen's content, to tell landscape from portrait on iPhone Duo unfolded.
    @State private var contentSize: CGSize = .zero

    /// Whether the settings show in an inspector column next to the gallery instead of behind the format button:
    /// on iPad in regular width, and on iPhone in regular width when the display is wider than tall,
    /// e.g. iPhone Duo unfolded in landscape. In portrait there's no room for a column beside the gallery,
    /// so the format button and its sheet are used there.
    private var isInspectorLayout: Bool {
        guard horizontalSizeClass == .regular else { return false }

        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return true
        case .phone:
            return contentSize.width > contentSize.height
        default:
            return false
        }
    }

    /// Whether the settings are already on screen, so the format button isn't needed.
    private var areSettingsShownInline: Bool {
        isInspectorLayout && isInspectorVisible
    }

    /// On iPad, the inspector shows once there are images to convert. On iPhone it's always shown,
    /// so the settings don't come and go in landscape.
    private var isInspectorVisible: Bool {
        UIDevice.current.userInterfaceIdiom == .phone || !inputService.items.isEmpty
    }
    
    private let previewLoader: ImagePreviewLoader
    private let fileURLFor: @MainActor (InputItem) async throws -> URL
    private let onConvert: ([InputItem], ImageFormat) -> Void
    private let onSendFeedback: () -> Void

    /// Creates an InputView.
    /// - Parameters:
    ///   - previewLoader: Loads the previews shown in the gallery.
    ///   - fileURLFor: Closure to resolve file URL from an InputItem.
    ///   - onConvert: Action to perform when conversion is initiated.
    ///   - onSendFeedback: Action to perform when the user wants to send feedback.
    init(
        previewLoader: ImagePreviewLoader,
        fileURLFor: @escaping @MainActor (InputItem) async throws -> URL,
        onConvert: @escaping ([InputItem], ImageFormat) -> Void,
        onSendFeedback: @escaping () -> Void
    ) {
        self.previewLoader = previewLoader
        self.fileURLFor = fileURLFor
        self.onConvert = onConvert
        self.onSendFeedback = onSendFeedback
    }

    private var content: some View {
        // The gallery is the root view, so the navigation bar tracks its scrolling and collapses the title smoothly.
        ImageGallery(
            items: inputService.items.map { item in
                ImageGallery.Item(
                    id: item.id.uuidString,
                    loadPreview: { @concurrent [previewLoader, fileURLFor] in
                        let url = try await fileURLFor(item)
                        return try await previewLoader.preview(for: url, cacheKey: item.id.uuidString)
                    },
                    cachedPreview: { [previewLoader] in
                        previewLoader.cachedPreview(forKey: item.id.uuidString)
                    },
                    contextActions: [
                        ContextAction(
                            title: String(localized: "button.remove"),
                            systemImage: "trash",
                            destructive: true,
                            execute: { inputService.didRemove(items: [item]) }
                        )
                    ]
                )
            }
        )
        .overlay {
            if inputService.items.isEmpty {
                EmptyView(
                    addFromPhotosAction: { sheet = .photoPicker },
                    addFromFilesAction: { sheet = .filePicker }
                )
                .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.25), value: inputService.items.isEmpty)
        .onDrop(of: [.image], isTargeted: $isDropTargeted) { providers in
            let items = providers
                .filter { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }
                .map(InputItem.init(itemProvider:))
            inputService.didAdd(items: items)
            return !items.isEmpty
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 3, dash: [10, 6]))
                    .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        .animation(.smooth(duration: 0.2), value: isDropTargeted)
        // Convert is the screen's confirming action, so it takes the prominent trailing spot, as Send does
        // in Mail; on iPhone Duo it's pinned to the top of the vertical bar, so it never scrolls away.
        // It's always there, just disabled without images, so the bar never shifts.
        .toolbarProminentAction {
            ConvertToolbarButton(action: convert)
                .disabled(inputService.items.isEmpty)
        }
        // Real toolbar items rather than a custom bar, so they move into the vertical bar on iPhone Duo.
        // Once there are images, adding more is a single prominent button in the trailing corner, within
        // reach of the right thumb; the format sits opposite it on iPhone (iPad shows it in the inspector).
        .toolbarPreferringVerticalBar {
            if !inputService.items.isEmpty {
                if !areSettingsShownInline {
                    ToolbarItem(placement: .bottomBar) {
                        FormatToolbarButton(
                            selectedImageFormat: selectedImageFormat,
                            selectedImageCompressionQuality: selectedImageCompressionQuality,
                            action: { isFormatSheetPresented = true }
                        )
                    }
                }

                ToolbarSpacer(.flexible, placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    ImageSourceSelection(
                        addFromPhotosAction: { sheet = .photoPicker },
                        addFromFilesAction: { sheet = .filePicker }
                    )
                }
            }
        }
        .toolbarOverflowMenu(title: String(localized: "button.more")) {
            Button(role: .destructive, action: { isStartOverConfirmationShown = true }) {
                Label {
                    Text(String(localized: "button.startOver"))
                    Text(String(localized: "label.startOverSubtitle"))
                } icon: {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
            .disabled(inputService.items.isEmpty)

            Divider()

            Button(
                String(localized: "button.sendFeedback"),
                systemImage: "envelope",
                action: onSendFeedback
            )
        }
        .confirmationDialog(
            String(localized: "alert.removeAllImages"),
            isPresented: $isStartOverConfirmationShown,
            titleVisibility: .visible
        ) {
            Button(String(localized: "button.removeAllImages"), role: .destructive) {
                inputService.removeAll()
            }
        } message: {
            Text(String(localized: "alert.removeAllImages.message"))
        }
        .sheet(isPresented: $isFormatSheetPresented) {
            FormatSheet(
                selectedImageFormat: $selectedImageFormat,
                selectedImageCompressionQuality: $selectedImageCompressionQuality,
                prefersFullHeight: usesVerticalBars
            )
        }
        .onVerticalBarChange { usesVerticalBars = $0 }
        .sensoryFeedback(.impact(weight: .light), trigger: inputService.items.count) { old, new in new > old }
        .imagePicker(
            isPresented: $sheet[isPresented: .photoPicker],
            selectionLimit: 0
        ) { items in
            inputService.didAdd(items: items)
        }
        // The system file importer, which adapts to every device, including the vertical bar of iPhone Duo.
        .fileImporter(
            isPresented: $sheet[isPresented: .filePicker],
            allowedContentTypes: [.tiff, .bmp, .heic, .webP, .jpeg, .png],
            allowsMultipleSelection: true
        ) { result in
            guard case let .success(urls) = result else { return }
            inputService.didAdd(items: urls.map { url in
                InputItem(source: .fileURL(url))
            })
        }
        .navigationTitle(String(localized: "app.name"))
    }

    var body: some View {
        layout
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { size in
                contentSize = size
            }
    }

    @ViewBuilder
    private var layout: some View {
        // The inspector is only attached where it shows as a column. Elsewhere it would still wrap the
        // navigation stack's content in a container that disturbs the large title's collapse on scroll.
        if isInspectorLayout {
            content
                .inspector(isPresented: .constant(isInspectorVisible)) {
                    FormatInspector(
                        selectedImageFormat: $selectedImageFormat,
                        selectedImageCompressionQuality: $selectedImageCompressionQuality
                    )
                    .inspectorColumnWidth(min: 300, ideal: 340, max: 420)
                }
        } else {
            content
        }
    }
}

extension InputView {
    private func convert() {
        let outputFormat = ImageFormat(
            imageFormatSelection: selectedImageFormat,
            imageCompressionQuality: selectedImageCompressionQuality
        )
        onConvert(inputService.items, outputFormat)
    }
}

private extension InputView.Sheet? {
    subscript(isPresented sheet: InputView.Sheet) -> Bool {
        get {
            if case sheet = self {
                return true
            } else {
                return false
            }
        }
        set {
            if !newValue {
                self = nil
            }
        }
    }
}

/// Extension providing initialization from FormatSelection.
extension ImageFormat {
    /// Creates an ImageFormat from a FormatSelection and compression quality.
    /// - Parameters:
    ///   - imageFormatSelection: The selected format (lossy or lossless).
    ///   - imageCompressionQuality: The compression quality (used for lossy formats).
    init(
        imageFormatSelection: FormatSelection,
        imageCompressionQuality: ImageCompressionQuality
    ) {
        switch imageFormatSelection {
        case let .lossy(format):
            self = .lossy(format, compressionQuality: imageCompressionQuality)
        case let .lossless(format):
            self = .lossless(format)
        }
    }
}
