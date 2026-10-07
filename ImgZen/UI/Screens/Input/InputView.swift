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

    /// Regular width windows (iPad) show the settings in an inspector column instead of a bottom panel.
    private var isInspectorLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var isBottomControlPanelVisible: Bool {
        !inputService.items.isEmpty
    }
    
    private let imageData: @MainActor (ImageSource, ImageResolution) async throws -> ImageData
    private let metadata: @MainActor (ImageSource) throws -> ImageMetadata
    private let fileURLFor: @MainActor (InputItem) async throws -> URL
    private let onConvert: ([InputItem], ImageFormat) -> Void
    private let onSendFeedback: () -> Void

    /// Creates an InputView.
    /// - Parameters:
    ///   - imageData: Closure to retrieve image data at a given resolution.
    ///   - metadata: Closure to retrieve image metadata.
    ///   - fileURLFor: Closure to resolve file URL from an InputItem.
    ///   - onConvert: Action to perform when conversion is initiated.
    ///   - onSendFeedback: Action to perform when the user wants to send feedback.
    init(
        imageData: @escaping @MainActor (ImageSource, ImageResolution) async throws -> ImageData,
        metadata: @escaping @MainActor (ImageSource) throws -> ImageMetadata,
        fileURLFor: @escaping @MainActor (InputItem) async throws -> URL,
        onConvert: @escaping ([InputItem], ImageFormat) -> Void,
        onSendFeedback: @escaping () -> Void
    ) {
        self.imageData = imageData
        self.metadata = metadata
        self.fileURLFor = fileURLFor
        self.onConvert = onConvert
        self.onSendFeedback = onSendFeedback
    }

    var body: some View {
        // The gallery is the root view, so the navigation bar tracks its scrolling and collapses the title smoothly.
        ImageGallery(
            items: inputService.items.map { item in
                ImageGallery.Item(
                    id: item.id.uuidString,
                    imageInfo: { @concurrent in
                        let url = try await fileURLFor(item)
                        let imageData = try await imageData(url, .thumbnail)
                        let metadata = try await metadata(url)
                        return (metadata, imageData)
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
                // Lets touches through, so pulling down still reaches the gallery and the navigation bar beneath.
                EmptyView()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.25), value: inputService.items.isEmpty)
        .safeAreaBar(edge: .bottom) {
            // The actions sit at the bottom edge, with the most used ones on the trailing side,
            // so they're within thumb reach when holding the device in one hand.
            if inputService.items.isEmpty {
                AddImagesBar(
                    addFromPhotosAction: { sheet = .photoPicker },
                    addFromFilesAction: { sheet = .filePicker }
                )
            } else if !isInspectorLayout {
                BottomControlPanel(
                    selectedImageFormat: $selectedImageFormat,
                    selectedImageCompressionQuality: $selectedImageCompressionQuality,
                    addFromPhotosAction: { sheet = .photoPicker },
                    addFromFilesAction: { sheet = .filePicker },
                    onConvert: convert
                )
            }
        }
        .inspector(isPresented: .constant(isBottomControlPanelVisible && isInspectorLayout)) {
            FormatInspector(
                selectedImageFormat: $selectedImageFormat,
                selectedImageCompressionQuality: $selectedImageCompressionQuality,
                addFromPhotosAction: { sheet = .photoPicker },
                addFromFilesAction: { sheet = .filePicker },
                onConvert: convert
            )
            .inspectorColumnWidth(min: 300, ideal: 340, max: 420)
        }
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu(String(localized: "button.more"), systemImage: "ellipsis") {
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
                // Anchored to the menu button, so iPad shows it as a popover pointing at it.
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
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: inputService.items.count) { old, new in new > old }
        .imagePicker(
            isPresented: $sheet[isPresented: .photoPicker],
            selectionLimit: 0
        ) { items in
            inputService.didAdd(items: items)
        }
        .documentPicker(
            isPresented: $sheet[isPresented: .filePicker],
            allowedContentTypes: [.tiff, .bmp, .heic, .webP, .jpeg, .png]
        ) { urls in
            inputService.didAdd(items: urls.map { url in
                InputItem(source: .fileURL(url))
            })
        }
        .navigationTitle(String(localized: "app.name"))
        // An inline title, as in Photos: the grid scrolls under a steady bar instead of collapsing a large title.
        .navigationBarTitleDisplayMode(.inline)
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
