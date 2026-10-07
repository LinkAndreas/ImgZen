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
        settings
            .safeAreaBar(edge: .top) {
                // Makes clear that the formats listed are the ones the images are converted to.
                Label(String(localized: "label.destinationFormat"), systemImage: "photo")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .accessibilityAddTraits(.isHeader)
            }
    }

    private var settings: some View {
        FormatSettingsForm(
            selectedImageFormat: $selectedImageFormat,
            selectedImageCompressionQuality: $selectedImageCompressionQuality
        )
        .safeAreaBar(edge: .bottom) {
            // Same order as on iPhone, with Add in the trailing corner.
            HStack(spacing: 12) {
                ConvertButton(action: onConvert)
                ImageSourceSelection(
                    addFromPhotosAction: addFromPhotosAction,
                    addFromFilesAction: addFromFilesAction
                )
            }
            .padding(16)
        }
    }
}
