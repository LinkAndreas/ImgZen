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

    @State private var isDiscardAllConfirmationShown: Bool = false
    @State private var sheet: Sheet?
    @State private var selectedImageFormat: FormatSelection = .lossy(.jpeg)
    @State private var selectedImageCompressionQuality: ImageCompressionQuality = 0.9
    @State private var inputService = InputService()
    @State private var isSidePanelLayout = false
    @State private var isDropTargeted = false

    /// Window width from which the control panel moves next to the gallery instead of below it.
    nonisolated private static let sidePanelMinimumWidth: CGFloat = 900

    private var isBottomControlPanelVisible: Bool {
        !inputService.items.isEmpty
    }
    
    private let imageData: @MainActor (ImageSource, ImageResolution) async throws -> ImageData
    private let metadata: @MainActor (ImageSource) throws -> ImageMetadata
    private let fileURLFor: @MainActor (InputItem) async throws -> URL
    private let onConvert: ([InputItem], ImageFormat) -> Void

    /// Creates an InputView.
    /// - Parameters:
    ///   - imageData: Closure to retrieve image data at a given resolution.
    ///   - metadata: Closure to retrieve image metadata.
    ///   - fileURLFor: Closure to resolve file URL from an InputItem.
    ///   - onConvert: Action to perform when conversion is initiated.
    init(
        imageData: @escaping @MainActor (ImageSource, ImageResolution) async throws -> ImageData,
        metadata: @escaping @MainActor (ImageSource) throws -> ImageMetadata,
        fileURLFor: @escaping @MainActor (InputItem) async throws -> URL,
        onConvert: @escaping ([InputItem], ImageFormat) -> Void
    ) {
        self.imageData = imageData
        self.metadata = metadata
        self.fileURLFor = fileURLFor
        self.onConvert = onConvert
    }

    var body: some View {
        ZStack {
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

            EmptyView(
                addFromPhotosAction: { sheet = .photoPicker },
                addFromFilesAction: { sheet = .filePicker }
            )
            .opacity(inputService.items.isEmpty ? 1.0 : 0.0)
        }
        .safeAreaInset(edge: .bottom) {
            if isBottomControlPanelVisible && !isSidePanelLayout {
                bottomControlPanel
            }
        }
        .safeAreaInset(edge: .trailing) {
            if isBottomControlPanelVisible && isSidePanelLayout {
                bottomControlPanel
                    .frame(width: 400)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
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
        .onGeometryChange(for: Bool.self) { geometry in
            geometry.size.width >= Self.sidePanelMinimumWidth
        } action: { isWide in
            isSidePanelLayout = isWide
        }
        .toolbar {
            if !inputService.items.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    Button(
                        "",
                        systemImage: "trash",
                        action: { isDiscardAllConfirmationShown.toggle() }
                    )
                    .alert(
                        String(localized: "alert.removeAllImages"),
                        isPresented: $isDiscardAllConfirmationShown,
                        actions: {
                            Button(String(localized: "button.remove"), role: .destructive, action: {
                                inputService.removeAll()
                            })

                            Button(String(localized: "button.cancel"), role: .cancel) {
                                isDiscardAllConfirmationShown = false
                            }
                        }
                    )
                }
            }

            if !inputService.items.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    ImageSourceSelection(
                        addFromPhotosAction: { sheet = .photoPicker },
                        addFromFilesAction: { sheet = .filePicker }
                    )
                }
            }
        }
        .imagePicker(
            isPresented: $sheet[isPresented: .photoPicker],
            selectionLimit: 0
        ) { items in
            inputService.didAdd(items: items)
        }
        .fileImporter(
            isPresented: $sheet[isPresented: .filePicker],
            allowedContentTypes: [.tiff, .bmp, .heic, .webP, .jpeg, .png],
            allowsMultipleSelection: true,
            onCompletion: { result in
                switch result {
                case let .success(urls):
                    inputService.didAdd(items: urls.map { url in
                        InputItem(source: .fileURL(url))
                    })
                case let .failure(error):
                    logger.error("Failed to load data: \(error)")
                    return
                }
            }
        )
        .backgroundStyle(Color(.systemGroupedBackground))
        .navigationTitle(String(localized: "app.name"))
    }
}

extension InputView {
    private var bottomControlPanel: some View {
        BottomControlPanel(
            selectedImageFormat: $selectedImageFormat,
            selectedImageCompressionQuality: $selectedImageCompressionQuality,
            onConvert: {
                let outputFormat = ImageFormat(
                    imageFormatSelection: selectedImageFormat,
                    imageCompressionQuality: selectedImageCompressionQuality
                )
                onConvert(inputService.items, outputFormat)
            }
        )
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
