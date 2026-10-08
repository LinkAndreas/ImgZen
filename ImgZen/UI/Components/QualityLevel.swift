import SwiftUI

/// The named quality levels of lossy formats, each standing for a typical use.
enum QualityLevel: CaseIterable, Identifiable {
    case maximum
    case high
    case medium
    case low

    var id: Self { self }

    var title: String {
        switch self {
        case .maximum: String(localized: "quality.max")
        case .high: String(localized: "quality.high")
        case .medium: String(localized: "quality.med")
        case .low: String(localized: "quality.low")
        }
    }

    /// What the level is good for.
    var subtitle: String {
        switch self {
        case .maximum: String(localized: "quality.max.subtitle")
        case .high: String(localized: "quality.high.subtitle")
        case .medium: String(localized: "quality.med.subtitle")
        case .low: String(localized: "quality.low.subtitle")
        }
    }

    var quality: ImageCompressionQuality {
        switch self {
        case .maximum: 1.0
        case .high: 0.9
        case .medium: 0.75
        case .low: 0.6
        }
    }

    /// The level with exactly this quality, or nil for a custom quality.
    init?(quality: ImageCompressionQuality) {
        guard let level = Self.allCases.first(where: { $0.quality == quality }) else { return nil }
        self = level
    }
}

/// The slider for an exact quality, shown when the user chooses a custom quality.
struct CompressionQualitySlider: View {
    @Binding var quality: Double

    /// Lower qualities give images with visible artifacts, so the slider starts here.
    static let minimumQuality = 0.1

    /// Rounds slider values to whole percents, so the displayed value is exactly what's used.
    private var roundedQuality: Binding<Double> {
        Binding(
            get: { quality },
            set: { quality = ($0 * 100).rounded() / 100 }
        )
    }

    var body: some View {
        VStack(spacing: 6) {
            // No step: a stepped slider draws tick marks, which at 90 steps look like a second track.
            // The binding rounds to whole percents instead.
            Slider(value: roundedQuality, in: Self.minimumQuality...1.0) {
                Text(String(localized: "label.compressionQuality"))
            }
            .accessibilityValue(quality.formatted(.percent.precision(.fractionLength(0))))

            HStack {
                Text(String(localized: "quality.mostCompression"))
                Spacer()
                Text(String(localized: "quality.highestQuality"))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    @Previewable @State var quality: Double = 0.84

    Form {
        CompressionQualitySlider(quality: $quality)
    }
}
