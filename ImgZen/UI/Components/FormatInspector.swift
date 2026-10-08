import SwiftUI

/// Conversion settings shown in an inspector column next to the gallery on wide screens.
/// Lists all formats directly, since there's room to; Convert and Add live in the toolbar and bottom bar,
/// in the same places as on iPhone.
struct FormatInspector: View {
    @Binding private var selectedImageFormat: FormatSelection
    @Binding private var selectedImageCompressionQuality: ImageCompressionQuality
    private let estimateFileSize: FileSizeEstimation?
    private let estimationSubject: String?

    /// Creates a format inspector.
    /// - Parameters:
    ///   - selectedImageFormat: Binding to the selected image format.
    ///   - selectedImageCompressionQuality: Binding to the compression quality value.
    ///   - estimateFileSize: Estimates the file size shown with the quality.
    ///   - estimationSubject: Changes when the images change, so the estimate is made again.
    init(
        selectedImageFormat: Binding<FormatSelection>,
        selectedImageCompressionQuality: Binding<ImageCompressionQuality>,
        estimateFileSize: FileSizeEstimation? = nil,
        estimationSubject: String? = nil
    ) {
        self._selectedImageFormat = selectedImageFormat
        self._selectedImageCompressionQuality = selectedImageCompressionQuality
        self.estimateFileSize = estimateFileSize
        self.estimationSubject = estimationSubject
    }

    var body: some View {
        FormatSettingsForm(
            selectedImageFormat: $selectedImageFormat,
            selectedImageCompressionQuality: $selectedImageCompressionQuality,
            estimateFileSize: estimateFileSize,
            estimationSubject: estimationSubject
        )
        .safeAreaBar(edge: .top) {
            // Makes clear that the formats listed are the ones the images are converted to.
            Text(String(localized: "label.destinationFormat"))
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .accessibilityAddTraits(.isHeader)
        }
    }
}
