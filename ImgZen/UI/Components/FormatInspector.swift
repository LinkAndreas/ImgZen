import SwiftUI

/// Conversion settings shown in an inspector column next to the gallery on wide screens.
/// Lists all formats directly, since there's room to, and keeps the actions at the bottom.
struct FormatInspector: View {
    @Binding private var selectedImageFormat: FormatSelection
    @Binding private var selectedImageCompressionQuality: ImageCompressionQuality
    private let addFromPhotosAction: () -> Void
    private let addFromFilesAction: () -> Void
    private let onConvert: () -> Void

    /// Creates a format inspector.
    /// - Parameters:
    ///   - selectedImageFormat: Binding to the selected image format.
    ///   - selectedImageCompressionQuality: Binding to the compression quality value.
    ///   - addFromPhotosAction: Action to open photo picker.
    ///   - addFromFilesAction: Action to open file picker.
    ///   - onConvert: Action to perform when convert button is tapped.
    init(
        selectedImageFormat: Binding<FormatSelection>,
        selectedImageCompressionQuality: Binding<ImageCompressionQuality>,
        addFromPhotosAction: @escaping () -> Void,
        addFromFilesAction: @escaping () -> Void,
        onConvert: @escaping () -> Void
    ) {
        self._selectedImageFormat = selectedImageFormat
        self._selectedImageCompressionQuality = selectedImageCompressionQuality
        self.addFromPhotosAction = addFromPhotosAction
        self.addFromFilesAction = addFromFilesAction
        self.onConvert = onConvert
    }

    var body: some View {
        Form {
            Section(String(localized: "section.lossyFormats")) {
                ForEach(LossyImageFormat.allCases) { format in
                    FormatListEntry(
                        title: format.title,
                        subtitle: format.subtitle,
                        isSelected: selectedImageFormat == .lossy(format),
                        action: { selectedImageFormat = .lossy(format) }
                    )
                }
            }

            Section(String(localized: "section.losslessFormats")) {
                ForEach(LosslessImageFormat.allCases) { format in
                    FormatListEntry(
                        title: format.title,
                        subtitle: format.subtitle,
                        isSelected: selectedImageFormat == .lossless(format),
                        action: { selectedImageFormat = .lossless(format) }
                    )
                }
            }

            if selectedImageFormat.isLossy {
                Section(String(localized: "label.compressionQuality")) {
                    CompressionQualityPicker(quality: $selectedImageCompressionQuality)
                        .padding(.vertical, 8)
                }
            }
        }
        .animation(.smooth(duration: 0.2), value: selectedImageFormat.isLossy)
        .onChange(of: selectedImageFormat) {
            selectedImageCompressionQuality = 0.9
        }
        .safeAreaBar(edge: .bottom) {
            HStack(spacing: 12) {
                ImageSourceSelection(
                    addFromPhotosAction: addFromPhotosAction,
                    addFromFilesAction: addFromFilesAction
                )
                ConvertButton(action: onConvert)
            }
            .padding(16)
        }
    }
}
