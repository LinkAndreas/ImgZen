import SwiftUI

/// The floating controls at the bottom of the input screen once images are added:
/// the output format on the leading side (iPhone only; iPad shows it in the inspector),
/// and one prominent button for adding more images in the trailing corner, where the thumb rests.
struct BottomControlPanel: View {
    @State private var isFormatSheetPresented = false
    @Binding private var selectedImageFormat: FormatSelection
    @Binding private var selectedImageCompressionQuality: ImageCompressionQuality
    private let showsFormatButton: Bool
    private let estimateFileSize: FileSizeEstimation?
    private let estimationSubject: String?
    private let addFromPhotosAction: () -> Void
    private let addFromFilesAction: () -> Void

    /// Creates a bottom control panel.
    /// - Parameters:
    ///   - selectedImageFormat: Binding to the selected image format.
    ///   - selectedImageCompressionQuality: Binding to the compression quality value.
    ///   - showsFormatButton: Whether to show the format button, for screens without an inspector.
    ///   - estimateFileSize: Estimates the file size shown with the quality.
    ///   - estimationSubject: Changes when the images change, so the estimate is made again.
    ///   - addFromPhotosAction: Action to open photo picker.
    ///   - addFromFilesAction: Action to open file picker.
    init(
        selectedImageFormat: Binding<FormatSelection>,
        selectedImageCompressionQuality: Binding<ImageCompressionQuality>,
        showsFormatButton: Bool,
        estimateFileSize: FileSizeEstimation? = nil,
        estimationSubject: String? = nil,
        addFromPhotosAction: @escaping () -> Void,
        addFromFilesAction: @escaping () -> Void
    ) {
        self._selectedImageFormat = selectedImageFormat
        self._selectedImageCompressionQuality = selectedImageCompressionQuality
        self.showsFormatButton = showsFormatButton
        self.estimateFileSize = estimateFileSize
        self.estimationSubject = estimationSubject
        self.addFromPhotosAction = addFromPhotosAction
        self.addFromFilesAction = addFromFilesAction
    }

    var body: some View {
        HStack(spacing: 12) {
            if showsFormatButton {
                formatButton
            }

            Spacer(minLength: 0)

            ImageSourceSelection(
                addFromPhotosAction: addFromPhotosAction,
                addFromFilesAction: addFromFilesAction
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .sheet(isPresented: $isFormatSheetPresented) {
            FormatSheet(
                selectedImageFormat: $selectedImageFormat,
                selectedImageCompressionQuality: $selectedImageCompressionQuality,
                estimateFileSize: estimateFileSize,
                estimationSubject: estimationSubject
            )
        }
    }

    /// Shows what the images become, e.g. "JPEG · 90%", and opens the format settings.
    private var formatButton: some View {
        Button(action: { isFormatSheetPresented = true }) {
            HStack(spacing: 8) {
                Image(systemName: "photo")
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                Text(selectedImageFormat.title)
                    .fontWeight(.semibold)

                if selectedImageFormat.isLossy {
                    Text(selectedImageCompressionQuality.formatted(.percent.precision(.fractionLength(0))))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: selectedImageCompressionQuality))
                }

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .lineLimit(1)
            .fixedSize()
        }
        .buttonStyle(.glass)
        .controlSize(.large)
        .animation(.smooth(duration: 0.2), value: selectedImageCompressionQuality)
        .accessibilityLabel(String(localized: "label.destinationFormat"))
        .accessibilityValue(
            selectedImageFormat.isLossy
                ? "\(selectedImageFormat.title), \(selectedImageCompressionQuality.formatted(.percent.precision(.fractionLength(0))))"
                : selectedImageFormat.title
        )
    }
}
