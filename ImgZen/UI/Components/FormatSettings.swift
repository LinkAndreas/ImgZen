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

    var body: some View {
        Form {
            Section {
                ForEach(LossyImageFormat.allCases) { format in
                    FormatListEntry(
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

            Section {
                ForEach(LosslessImageFormat.allCases) { format in
                    FormatListEntry(
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

            // Always shown, and only disabled for lossless formats, so the rows above never move while choosing.
            Section {
                CompressionQualityPicker(quality: qualityBinding)
                    .disabled(selectedImageFormat.isLossless)
            } header: {
                Text(String(localized: "label.compressionQuality"))
            } footer: {
                Text(qualityFooter)
            }
        }
        .sensoryFeedback(.selection, trigger: selectedImageFormat)
        .onChange(of: selectedImageFormat) {
            selectedImageCompressionQuality = 0.9
        }
    }

    /// Lossless formats always keep every detail, so their quality reads as 100%.
    private var qualityBinding: Binding<ImageCompressionQuality> {
        selectedImageFormat.isLossy ? $selectedImageCompressionQuality : .constant(1.0)
    }

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
        .presentationDetents([.medium, .large])
        .toolbarStaysInTopBar()
    }
}

/// A list entry for selecting an image format.
struct FormatListEntry: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
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
