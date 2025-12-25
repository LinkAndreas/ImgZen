import SwiftUI

/// A picker component for selecting image compression quality with preset buttons and a slider.
struct CompressionQualityPicker: View {
    @Binding var quality: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                QualityButton(title: String(localized: "quality.low"), value: 0.60, selectedQuality: $quality)
                QualityButton(title: String(localized: "quality.med"), value: 0.75, selectedQuality: $quality)
                QualityButton(title: String(localized: "quality.high"), value: 0.90, selectedQuality: $quality)
                QualityButton(title: String(localized: "quality.max"), value: 1.0, selectedQuality: $quality)
            }

            VStack(spacing: 8) {
                Slider(value: $quality, in: 0.0...1.0, step: 0.01)
                    .accentColor(.accent)

                HStack {
                    Text(String(localized: "quality.mostCompression"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(quality.formatted(.percent.precision(.fractionLength(0))))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(String(localized: "quality.highestQuality"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedQuality = value
            }
        }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.red : Color(uiColor: .systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .shadow(color: isSelected ? Color.red.opacity(0.3) : Color.clear,
                       radius: isSelected ? 4 : 0, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    @Previewable @State var compressionQuality: Double = 0.75

    CompressionQualityPicker(quality: $compressionQuality)
}
