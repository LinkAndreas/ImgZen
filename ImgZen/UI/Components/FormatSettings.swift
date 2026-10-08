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

    /// A choice in the quality menu: a named level, or an exact value set with the slider.
    private enum QualityChoice: Hashable {
        case level(QualityLevel)
        case custom
    }

    private var qualityChoice: Binding<QualityChoice> {
        Binding(
            get: {
                guard !isCustomQuality, let level = QualityLevel(quality: selectedImageCompressionQuality) else {
                    return .custom
                }
                return .level(level)
            },
            set: { choice in
                switch choice {
                case let .level(level):
                    isCustomQuality = false
                    selectedImageCompressionQuality = level.quality
                case .custom:
                    isCustomQuality = true
                }
            }
        )
    }

    /// One row with a menu of the levels, as Settings does for secondary choices; the footer explains
    /// only the chosen level, so the section stays short. Custom adds a slider for an exact value.
    private var qualitySection: some View {
        Section {
            Picker(String(localized: "label.compressionQuality"), selection: qualityChoice) {
                ForEach(QualityLevel.allCases) { level in
                    Text(level.title)
                        .tag(QualityChoice.level(level))
                }

                Divider()

                Text(String(localized: "quality.custom"))
                    .tag(QualityChoice.custom)
            }
            .pickerStyle(.menu)

            if isCustomQuality {
                CompressionQualitySlider(quality: $selectedImageCompressionQuality)
            }
        } footer: {
            Text(qualityFooter)
                .contentTransition(.opacity)
        }
    }
}

extension FormatSettingsForm {
    /// Explains the chosen level, a custom quality, or why the quality doesn't apply to a lossless format.
    private var qualityFooter: String {
        if selectedImageFormat.isLossless {
            String(format: String(localized: "label.compressionQuality.losslessFooter"), selectedImageFormat.title)
        } else if !isCustomQuality, let level = QualityLevel(quality: selectedImageCompressionQuality) {
            level.subtitle
        } else {
            String(localized: "label.compressionQuality.footer")
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
