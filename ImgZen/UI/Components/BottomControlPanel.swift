import SwiftUI

/// Floating controls at the bottom of compact screens, where they're easiest to reach:
/// add images, pick the output format and convert.
struct BottomControlPanel: View {
    @State private var isFormatSheetPresented = false
    @Binding private var selectedImageFormat: FormatSelection
    @Binding private var selectedImageCompressionQuality: ImageCompressionQuality
    private let addFromPhotosAction: () -> Void
    private let addFromFilesAction: () -> Void
    private let onConvert: () -> Void

    /// Creates a bottom control panel.
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
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                ImageSourceSelection(
                    addFromPhotosAction: addFromPhotosAction,
                    addFromFilesAction: addFromFilesAction
                )

                formatButton

                ConvertButton(action: onConvert)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: 600)
        .sheet(isPresented: $isFormatSheetPresented) {
            FormatSheet(
                selectedImageFormat: $selectedImageFormat,
                selectedImageCompressionQuality: $selectedImageCompressionQuality
            )
        }
    }

    /// Shows the chosen format, and its quality for lossy formats, so the settings are visible at a glance.
    private var formatButton: some View {
        Button(action: { isFormatSheetPresented = true }) {
            HStack(spacing: 6) {
                Text(selectedImageFormat.title)
                    .fontWeight(.semibold)

                if selectedImageFormat.isLossy {
                    Text(selectedImageCompressionQuality.formatted(.percent.precision(.fractionLength(0))))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
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
