import OSLog
import UniformTypeIdentifiers
import SwiftUI
import PhotosUI
import UIKit

/// The main input screen where users select images and configure conversion settings.
struct InputView: View {
    @Environment(\.appAccentColor) private var accentColor

    /// Enum representing sheet types that can be presented.
    enum Sheet {
        /// Photo picker sheet for selecting from photo library.
        case photoPicker
        /// File picker sheet for selecting from files.
        case filePicker
    }

    @State private var isClearAllConfirmationShown: Bool = false
    @State private var sheet: Sheet?
    @Binding private var selectedImageFormat: FormatSelection
    @Binding private var selectedImageCompressionQuality: ImageCompressionQuality
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isDropTargeted = false
    @State private var isFormatSheetPresented = false

    /// On iPad, Convert floats next to Add in the gallery, where the images are, rather than at the top
    /// of the inspector column. Elsewhere it's the prominent action at the top, pinned to the vertical bar
    /// on iPhone Duo.
    private var showsConvertNextToAdd: Bool {
        horizontalSizeClass == .regular && UIDevice.current.userInterfaceIdiom == .pad
    }

    private let inputService: InputService
    /// Whether the settings are already on screen in the inspector next to the navigation stack,
    /// so the format button isn't needed.
    private let areSettingsShownInline: Bool
    private let previewLoader: ImagePreviewLoader
    private let fileURLFor: @MainActor (InputItem) async throws -> URL
    private let onConvert: ([InputItem], ImageFormat) -> Void
    private let onSupportTheDeveloper: () -> Void
    private let onSendFeedback: () -> Void

    /// Creates an InputView.
    /// - Parameters:
    ///   - inputService: The images to convert.
    ///   - selectedImageFormat: Binding to the selected image format.
    ///   - selectedImageCompressionQuality: Binding to the compression quality value.
    ///   - areSettingsShownInline: Whether the format inspector shows next to the gallery.
    ///   - previewLoader: Loads the previews shown in the gallery.
    ///   - fileURLFor: Closure to resolve file URL from an InputItem.
    ///   - onConvert: Action to perform when conversion is initiated.
    ///   - onSupportTheDeveloper: Action to perform when the user wants to support the developer.
    ///   - onSendFeedback: Action to perform when the user wants to send feedback.
    init(
        inputService: InputService,
        selectedImageFormat: Binding<FormatSelection>,
        selectedImageCompressionQuality: Binding<ImageCompressionQuality>,
        areSettingsShownInline: Bool,
        previewLoader: ImagePreviewLoader,
        fileURLFor: @escaping @MainActor (InputItem) async throws -> URL,
        onConvert: @escaping ([InputItem], ImageFormat) -> Void,
        onSupportTheDeveloper: @escaping () -> Void,
        onSendFeedback: @escaping () -> Void
    ) {
        self.inputService = inputService
        self._selectedImageFormat = selectedImageFormat
        self._selectedImageCompressionQuality = selectedImageCompressionQuality
        self.areSettingsShownInline = areSettingsShownInline
        self.previewLoader = previewLoader
        self.fileURLFor = fileURLFor
        self.onConvert = onConvert
        self.onSupportTheDeveloper = onSupportTheDeveloper
        self.onSendFeedback = onSendFeedback
    }

    private func content(usesVerticalBars: Bool) -> some View {
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
                    .strokeBorder(accentColor, style: StrokeStyle(lineWidth: 3, dash: [10, 6]))
                    .background(accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(8)
                    .allowsHitTesting(false)
            }
        }
        .animation(.smooth(duration: 0.2), value: isDropTargeted)
        // Convert is the screen's confirming action, so it takes the prominent trailing spot, as Send does
        // in Mail; on iPhone Duo it's pinned to the top of the vertical bar, so it never scrolls away.
        // It's always there, just disabled without images, so the bar never shifts.
        .toolbarProminentAction(isShown: !showsConvertNextToAdd) {
            ConvertToolbarButton(action: convert)
                .disabled(inputService.items.isEmpty)
        }
        // Real toolbar items rather than a custom bar, so they move into the vertical bar on iPhone Duo.
        // Once there are images, adding more is a single prominent button in the trailing corner, within
        // reach of the right thumb; the format sits opposite it on iPhone (iPad shows it in the inspector).
        .toolbarPreferringVerticalBar {
            // Clearing is visible in the top bar once there's something to clear, opposite Convert, so it's
            // clear how to get back to an empty screen without searching a menu. "Clear All" says what it does,
            // where "Start Over" left open whether settings reset or files were deleted.
            if !inputService.items.isEmpty {
                ToolbarItem(placement: .topBarLeading) {
                    clearAllButton
                }
            }

            if !inputService.items.isEmpty && !areSettingsShownInline {
                ToolbarItem(placement: .bottomBar) {
                    FormatToolbarButton(
                        selectedImageFormat: selectedImageFormat,
                        selectedImageCompressionQuality: selectedImageCompressionQuality,
                        action: { isFormatSheetPresented = true }
                    )
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
        // Next to the inspector, the toolbar's bottom bar sits under the inspector column, so Add floats
        // in the gallery's trailing corner instead, by the images it adds to. On iPad, Convert joins it
        // as the prominent button, so the main action sits with the images too.
        .safeAreaBar(edge: .bottom) {
            if !inputService.items.isEmpty && areSettingsShownInline {
                GlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        Spacer()

                        if showsConvertNextToAdd {
                            Button(String(localized: "button.convert"), action: convert)
                                .buttonStyle(.glassProminent)
                                .controlSize(.large)
                                .keyboardShortcut(.return, modifiers: .command)
                        }

                        ImageSourceSelection(
                            style: showsConvertNextToAdd ? .floatingSecondary : .floating,
                            addFromPhotosAction: { sheet = .photoPicker },
                            addFromFilesAction: { sheet = .filePicker }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.opacity)
            }
        }
        .toolbarOverflowMenu(title: String(localized: "button.more")) {
            Button(
                String(localized: "button.supportTheDeveloper"),
                systemImage: "heart",
                action: onSupportTheDeveloper
            )

            Button(
                String(localized: "button.sendFeedback"),
                systemImage: "envelope",
                action: onSendFeedback
            )
        }
        .sheet(isPresented: $isFormatSheetPresented) {
            FormatSheet(
                selectedImageFormat: $selectedImageFormat,
                selectedImageCompressionQuality: $selectedImageCompressionQuality,
                prefersFullHeight: usesVerticalBars
            )
        }
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

    /// Clears all images after confirming; the title on horizontal bars, the icon in the vertical bar.
    /// The confirmation is attached to the button, so on iPad it points at the button that asked for it.
    private var clearAllButton: some View {
        Button(action: { isClearAllConfirmationShown = true }) {
            VerticalBarReader { isVertical in
                if isVertical {
                    Label(String(localized: "button.clearAll"), systemImage: "xmark.circle")
                        .labelStyle(.iconOnly)
                } else {
                    Text(String(localized: "button.clearAll"))
                }
            }
        }
        .confirmationDialog(
            String(localized: "alert.removeAllImages"),
            isPresented: $isClearAllConfirmationShown,
            titleVisibility: .visible
        ) {
            Button(String(localized: "button.removeAllImages"), role: .destructive) {
                inputService.removeAll()
            }
        } message: {
            Text(String(localized: "alert.removeAllImages.message"))
        }
    }

    var body: some View {
        // Whether bars are vertical comes from the environment (iPhone Duo), and decides how the format sheet opens.
        VerticalBarReader { usesVerticalBars in
            content(usesVerticalBars: usesVerticalBars)
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
