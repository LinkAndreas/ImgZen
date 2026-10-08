import SwiftUI

/// Represents a user's selection of either a lossy or lossless image format.
enum FormatSelection: Equatable {
    case lossy(LossyImageFormat)
    case lossless(LosslessImageFormat)

    var isLossy: Bool {
        switch self {
        case .lossy:
            return true
        case .lossless:
            return false
        }
    }

    var isLossless: Bool {
        return !isLossy
    }

    var lossyImageFormat: LossyImageFormat? {
        switch self {
        case let .lossy(format):
            return format
        case .lossless:
            return nil
        }
    }

    var losslessImageFormat: LosslessImageFormat? {
        switch self {
        case .lossy:
            return nil
        case let .lossless(format):
            return format
        }
    }
}

/// The conversion settings: the formats to convert to and, for lossy formats, the image quality.
/// Shared by the iPad inspector and the iPhone format sheet, so both offer the same options.
struct FormatSettingsForm: View {
    @Binding var selectedImageFormat: FormatSelection
    @Binding var selectedImageCompressionQuality: ImageCompressionQuality

    /// Whether the user chose to set an exact quality, which shows the slider.
    /// Kept apart from the value, so a custom quality that happens to match a level stays custom.
    @State private var isCustomQuality: Bool

    init(
        selectedImageFormat: Binding<FormatSelection>,
        selectedImageCompressionQuality: Binding<ImageCompressionQuality>
    ) {
        _selectedImageFormat = selectedImageFormat
        _selectedImageCompressionQuality = selectedImageCompressionQuality
        _isCustomQuality = State(initialValue: QualityLevel(quality: selectedImageCompressionQuality.wrappedValue) == nil)
    }

    var body: some View {
        Form {
            Section {
                ForEach(LossyImageFormat.allCases) { format in
                    OptionRow(
                        title: format.title,
                        subtitle: format.subtitle,
                        isSelected: selectedImageFormat == .lossy(format),
                        action: { selectedImageFormat = .lossy(format) }
                    )
                }
            } header: {
                Text(String(localized: "section.lossyFormats"))
            } footer: {
                Text(String(localized: "section.lossyFormats.footer"))
            }

            // Right below the lossy formats it applies to. It stays in place, just disabled, for lossless
            // formats, so the lossless rows below never move while choosing.
            qualitySection
                .disabled(selectedImageFormat.isLossless)

            Section {
                ForEach(LosslessImageFormat.allCases) { format in
                    OptionRow(
                        title: format.title,
                        subtitle: format.subtitle,
                        isSelected: selectedImageFormat == .lossless(format),
                        action: { selectedImageFormat = .lossless(format) }
                    )
                }
            } header: {
                Text(String(localized: "section.losslessFormats"))
            } footer: {
                Text(String(localized: "section.losslessFormats.footer"))
            }
        }
        // Content scrolls softly under the sheet's title bar instead of being cut off at a hard edge.
        .scrollEdgeEffectStyle(.soft, for: .top)
        .animation(.smooth(duration: 0.25), value: isCustomQuality)
        // The quality is kept when choosing another format, so trying JPEG, HEIC and WebP
        // doesn't throw away the quality the user picked.
        .sensoryFeedback(.selection, trigger: selectedImageFormat)
        .sensoryFeedback(.selection, trigger: isCustomQuality)
        .sensoryFeedback(.selection, trigger: QualityLevel(quality: selectedImageCompressionQuality))
    }

    /// The quality as named levels, like the formats above, each saying what it's good for;
    /// Custom reveals a slider for an exact value.
    private var qualitySection: some View {
        Section {
            ForEach(QualityLevel.allCases) { level in
                OptionRow(
                    title: level.title,
                    subtitle: level.subtitle,
                    value: level.quality.formatted(.percent.precision(.fractionLength(0))),
                    isSelected: !isCustomQuality && selectedImageCompressionQuality == level.quality,
                    action: {
                        isCustomQuality = false
                        selectedImageCompressionQuality = level.quality
                    }
                )
            }

            OptionRow(
                title: String(localized: "quality.custom"),
                subtitle: String(localized: "quality.custom.subtitle"),
                value: isCustomQuality
                    ? selectedImageCompressionQuality.formatted(.percent.precision(.fractionLength(0)))
                    : nil,
                isSelected: isCustomQuality,
                action: { isCustomQuality = true }
            )

            if isCustomQuality {
                CompressionQualitySlider(quality: $selectedImageCompressionQuality)
            }
        } header: {
            Text(String(localized: "label.compressionQuality"))
        } footer: {
            Text(qualityFooter)
        }
    }
}

extension FormatSettingsForm {
    /// Explains the quality, or why it doesn't apply to a lossless format.
    private var qualityFooter: String {
        if selectedImageFormat.isLossy {
            String(localized: "label.compressionQuality.footer")
        } else {
            String(format: String(localized: "label.compressionQuality.losslessFooter"), selectedImageFormat.title)
        }
    }
}

/// A sheet presenting the conversion settings on compact screens.
struct FormatSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedImageFormat: FormatSelection
    @Binding var selectedImageCompressionQuality: ImageCompressionQuality
    /// Whether the sheet opens at full height only, for when bars are vertical (iPhone Duo).
    var prefersFullHeight: Bool = false

    var body: some View {
        NavigationStack {
            FormatSettingsForm(
                selectedImageFormat: $selectedImageFormat,
                selectedImageCompressionQuality: $selectedImageCompressionQuality
            )
            .navigationTitle(String(localized: "label.destinationFormat"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: { dismiss() })
                }
            }
        }
        // Opening at half height keeps the formats and the done button within thumb reach.
        // With vertical bars, the sheet only gets its vertical bar at full height, so it opens there:
        // the done button then stays in the vertical bar instead of moving into it as the sheet grows.
        .presentationDetents(prefersFullHeight ? [.large] : [.medium, .large])
    }
}

/// A row for choosing one of several options, with a checkmark on the chosen one.
struct OptionRow: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    let subtitle: String
    /// A value shown before the checkmark, e.g. the percentage of a quality level.
    var value: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    // Explicit label colors: inside a button, the hierarchical styles resolve to the tint color.
                    // Disabled rows dim themselves, since explicit colors don't follow the disabled state.
                    Text(title)
                        .foregroundStyle(isEnabled ? Color(.label) : Color(.tertiaryLabel))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(isEnabled ? Color(.secondaryLabel) : Color(.tertiaryLabel))
                }

                Spacer(minLength: 0)

                if let value {
                    Text(value)
                        .foregroundStyle(isEnabled ? Color(.secondaryLabel) : Color(.tertiaryLabel))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tint)
                    .opacity(isSelected ? 1.0 : 0.0)
                    .accessibilityHidden(true)
            }
            .contentShape(.rect)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    FormatSheet(
        selectedImageFormat: .constant(.lossy(.jpeg)),
        selectedImageCompressionQuality: .constant(0.9)
    )
}
