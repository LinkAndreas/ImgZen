import SwiftUI

/// Picks the image quality of lossy formats, with presets for the common choices and a slider for fine-tuning.
/// Laid out as a single row, so a list shows it without separators between its parts.
struct CompressionQualityPicker: View {
    @Binding var quality: Double

    private static let presets: [(title: String, value: Double)] = [
        (String(localized: "quality.low"), 0.60),
        (String(localized: "quality.med"), 0.75),
        (String(localized: "quality.high"), 0.90),
        (String(localized: "quality.max"), 1.0)
    ]

    /// Rounds slider values to whole percents, so reaching a preset with the slider selects it exactly.
    private var roundedQuality: Binding<Double> {
        Binding(
            get: { quality },
            set: { quality = ($0 * 100).rounded() / 100 }
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker(String(localized: "label.compressionQuality"), selection: roundedQuality) {
                ForEach(Self.presets, id: \.value) { preset in
                    Text(preset.title).tag(preset.value)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    // No step: a stepped slider draws tick marks, which at 100 steps look like a second track.
                    // The binding rounds to whole percents instead.
                    Slider(value: roundedQuality, in: 0.0...1.0) {
                        Text(String(localized: "label.compressionQuality"))
                    }

                    Text(quality.formatted(.percent.precision(.fractionLength(0))))
                        .font(.body.weight(.semibold))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: quality))
                        .frame(minWidth: 48, alignment: .trailing)
                        .accessibilityHidden(true)
                }

                HStack {
                    Text(String(localized: "quality.mostCompression"))
                    Spacer()
                    Text(String(localized: "quality.highestQuality"))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 6)
        .animation(.snappy, value: quality)
        // Ticks when a preset is reached, by tapping it or by dragging the slider across it.
        .sensoryFeedback(.selection, trigger: quality) { _, quality in
            Self.presets.contains { $0.value == quality }
        }
    }
}

#Preview {
    @Previewable @State var compressionQuality: Double = 0.75

    Form {
        CompressionQualityPicker(quality: $compressionQuality)
    }
}
