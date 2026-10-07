import SwiftUI

/// A picker component for selecting image compression quality with preset buttons and a slider.
struct CompressionQualityPicker: View {
    @Binding var quality: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                QualityButton(title: String(localized: "quality.low"), value: 0.60, selectedQuality: $quality)
                QualityButton(title: String(localized: "quality.med"), value: 0.75, selectedQuality: $quality)
                QualityButton(title: String(localized: "quality.high"), value: 0.90, selectedQuality: $quality)
                QualityButton(title: String(localized: "quality.max"), value: 1.0, selectedQuality: $quality)
            }

            VStack(spacing: 8) {
                Slider(value: $quality, in: 0.0...1.0, step: 0.01) {
                    Text(String(localized: "label.compressionQuality"))
                }
                .tint(.accentColor)

                HStack {
                    Text(String(localized: "quality.mostCompression"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(quality.formatted(.percent.precision(.fractionLength(0))))
                        .font(.title2.bold())
                        .monospacedDigit()
                        .contentTransition(.numericText(value: quality))
                        .animation(.snappy, value: quality)

                    Spacer()

                    Text(String(localized: "quality.highestQuality"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityHidden(true)
            }
        }
    }
}

/// A button for selecting a preset compression quality value.
struct QualityButton: View {
    let title: String
    let value: Double
    @Binding var selectedQuality: Double

    var isSelected: Bool {
        selectedQuality == value
    }

    var body: some View {
        Button(action: {
            withAnimation(.snappy) {
                selectedQuality = value
            }
        }) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(isSelected ? Color.accentColor : Color(.tertiarySystemFill), in: .capsule)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        // Ticks when a preset is reached, by tapping it or by dragging the slider across it.
        .sensoryFeedback(.selection, trigger: isSelected) { _, isSelected in isSelected }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var compressionQuality: Double = 0.75

    CompressionQualityPicker(quality: $compressionQuality)
        .padding()
}
