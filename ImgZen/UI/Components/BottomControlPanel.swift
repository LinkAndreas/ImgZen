import SwiftUI

struct BottomControlPanel: View {
    @Binding private var selectedImageFormat: FormatSelection
    @Binding private var selectedImageCompressionQuality: ImageCompressionQuality
    private let fillsHeight: Bool
    private let addFromPhotosAction: () -> Void
    private let addFromFilesAction: () -> Void
    private let onConvert: () -> Void

    /// Creates a bottom control panel.
    /// - Parameters:
    ///   - selectedImageFormat: Binding to the selected image format.
    ///   - selectedImageCompressionQuality: Binding to the compression quality value.
    ///   - fillsHeight: Whether the panel stretches to the available height, keeping its actions at the bottom.
    ///   - addFromPhotosAction: Action to open photo picker.
    ///   - addFromFilesAction: Action to open file picker.
    ///   - onConvert: Action to perform when convert button is tapped.
    init(
        selectedImageFormat: Binding<FormatSelection>,
        selectedImageCompressionQuality: Binding<ImageCompressionQuality>,
        fillsHeight: Bool = false,
        addFromPhotosAction: @escaping () -> Void,
        addFromFilesAction: @escaping () -> Void,
        onConvert: @escaping () -> Void
    ) {
        self._selectedImageFormat = selectedImageFormat
        self._selectedImageCompressionQuality = selectedImageCompressionQuality
        self.fillsHeight = fillsHeight
        self.addFromPhotosAction = addFromPhotosAction
        self.addFromFilesAction = addFromFilesAction
        self.onConvert = onConvert
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            FormatPicker(
                selectedImageFormat: $selectedImageFormat,
                selectedImageCompressionQuality: $selectedImageCompressionQuality
            )

            if fillsHeight {
                Spacer(minLength: 0)
            }

            // The main actions sit at the bottom edge, where they're easiest to reach.
            HStack(spacing: 12) {
                ImageSourceSelection(
                    addFromPhotosAction: addFromPhotosAction,
                    addFromFilesAction: addFromFilesAction
                )
                ConvertButton(action: onConvert)
            }
        }
        .padding(20)
        .frame(maxHeight: fillsHeight ? .infinity : nil, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.secondarySystemBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 0.4)
        )
        .padding(20)
        .frame(maxWidth: 600)
    }
}
