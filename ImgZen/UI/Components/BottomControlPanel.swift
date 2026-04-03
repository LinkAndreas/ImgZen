import SwiftUI

struct BottomControlPanel: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Binding private var selectedImageFormat: FormatSelection
    @Binding private var selectedImageCompressionQuality: ImageCompressionQuality
    private let onConvert: () -> Void

    /// Creates a bottom control panel.
    /// - Parameters:
    ///   - selectedImageFormat: Binding to the selected image format.
    ///   - selectedImageCompressionQuality: Binding to the compression quality value.
    ///   - onConvert: Action to perform when convert button is tapped.
    init(
        selectedImageFormat: Binding<FormatSelection>,
        selectedImageCompressionQuality: Binding<ImageCompressionQuality>,
        onConvert: @escaping () -> Void
    ) {
        self._selectedImageFormat = selectedImageFormat
        self._selectedImageCompressionQuality = selectedImageCompressionQuality
        self.onConvert = onConvert
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            FormatPicker(
                selectedImageFormat: $selectedImageFormat,
                selectedImageCompressionQuality: $selectedImageCompressionQuality
            )
            ConvertButton(action: onConvert)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.secondarySystemBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 0.4)
        )
        .padding(20)
        .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
    }
}
