import SwiftUI

/// Picks the image quality of lossy formats.
///
/// The presets name ranges rather than exact values, so one is always selected: they choose the
/// rough level, and the slider fine-tunes within it. Below them, an estimate of the resulting file size
/// turns the abstract percentage into what it means. Laid out as a single row, so a list shows it
/// without separators between its parts.
struct CompressionQualityPicker: View {
    @Binding var quality: Double
    /// The estimated size of a converted image at this quality, if known.
    var estimate: FileSizeEstimate? = nil

    /// Lower qualities give images with visible artifacts, so the slider starts here.
    static let minimumQuality = 0.1

    /// The presets, each standing for the range of qualities closest to it.
    private enum Level: CaseIterable, Hashable {
        case low
        case medium
        case high
        case maximum

        var title: String {
            switch self {
            case .low: String(localized: "quality.low")
            case .medium: String(localized: "quality.med")
            case .high: String(localized: "quality.high")
            case .maximum: String(localized: "quality.max")
            }
        }

        /// The quality set when the preset is chosen.
        var quality: Double {
            switch self {
            case .low: 0.6
            case .medium: 0.75
            case .high: 0.9
            case .maximum: 1.0
            }
        }

        /// The preset whose range contains a quality: halfway between neighboring presets,
        /// except that Maximum only starts at 95%, since that's where files grow fastest.
        init(quality: Double) {
            switch quality {
            case ..<0.675: self = .low
            case ..<0.825: self = .medium
            case ..<0.95: self = .high
            default: self = .maximum
            }
        }
    }

    private var level: Binding<Level> {
        Binding(
            get: { Level(quality: quality) },
            set: { quality = $0.quality }
        )
    }

    /// Rounds slider values to whole percents, so the displayed value is exactly what's used.
    private var roundedQuality: Binding<Double> {
        Binding(
            get: { quality },
            set: { quality = ($0 * 100).rounded() / 100 }
        )
    }

    private var formattedQuality: String {
        quality.formatted(.percent.precision(.fractionLength(0)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker(String(localized: "label.compressionQuality"), selection: level) {
                ForEach(Level.allCases, id: \.self) { level in
                    Text(level.title).tag(level)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    // No step: a stepped slider draws tick marks, which at 90 steps look like a second track.
                    // The binding rounds to whole percents instead.
                    Slider(value: roundedQuality, in: Self.minimumQuality...1.0) {
                        Text(String(localized: "label.compressionQuality"))
                    }
                    .accessibilityValue("\(Level(quality: quality).title), \(formattedQuality)")

                    Text(formattedQuality)
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

            if let estimate {
                Label {
                    Text(Self.description(of: estimate))
                        .contentTransition(.numericText())
                } icon: {
                    Image(systemName: "doc")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 6)
        .animation(.snappy, value: quality)
        .animation(.smooth(duration: 0.2), value: estimate)
        // Ticks when the slider crosses into another preset's range, like detents.
        .sensoryFeedback(.selection, trigger: Level(quality: quality))
    }

    /// Describes an estimate, e.g. "About 1.2 MB per image · 61% smaller".
    private static func description(of estimate: FileSizeEstimate) -> String {
        let size = estimate.estimatedSize.formatted(.byteCount(style: .file))
        guard estimate.originalSize > 0 else {
            return String(format: String(localized: "label.estimate"), size)
        }

        let change = Double(estimate.estimatedSize) / Double(estimate.originalSize) - 1
        let formattedChange = abs(change).formatted(.percent.precision(.fractionLength(0)))
        if abs(change) < 0.05 {
            return String(format: String(localized: "label.estimate.similar"), size)
        } else if change < 0 {
            return String(format: String(localized: "label.estimate.smaller"), size, formattedChange)
        } else {
            return String(format: String(localized: "label.estimate.larger"), size, formattedChange)
        }
    }
}

#Preview {
    @Previewable @State var compressionQuality: Double = 0.84

    Form {
        CompressionQualityPicker(
            quality: $compressionQuality,
            estimate: FileSizeEstimate(estimatedSize: 1_200_000, originalSize: 3_100_000)
        )
    }
}
