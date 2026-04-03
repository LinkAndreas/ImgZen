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

/// A picker component for selecting image format with compression quality options.
struct FormatPicker: View {
    @Binding var selectedImageFormat: FormatSelection
    @Binding var selectedImageCompressionQuality: ImageCompressionQuality

    @State private var isCompressionQualitySectionExpanded: Bool = false
    @State private var isSheetVisible: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label(String(localized: "label.destinationFormat"), systemImage: "photo")
                .font(.headline)

            Button(action: { isSheetVisible = true }) {
                HStack {
                    Text(selectedImageFormat.title)
                        .font(.body)
                    Spacer()
                    Image(systemName: "chevron.down")
                }
            }
            .buttonBorderShape(.roundedRectangle)
            .buttonStyle(.custom)
            .sheet(isPresented: $isSheetVisible) {
                SheetContent(
                    selectedImageFormat: $selectedImageFormat,
                    close: { isSheetVisible = false }
                )
            }

            if selectedImageFormat.isLossy {
                DisclosureGroup(isExpanded: $isCompressionQualitySectionExpanded) {
                    CompressionQualityPicker(quality: $selectedImageCompressionQuality)
                        .padding(.top, 20)
                } label: {
                    Label(
                        String(localized: "label.compressionQuality"),
                        systemImage: "slider.horizontal.3"
                    )
                    .font(.headline)
                    .tint(Color.label)
                }
            }
        }
        .onChange(of: selectedImageFormat) {
            isCompressionQualitySectionExpanded = false
            selectedImageCompressionQuality = 0.9
        }
    }
}

/// Sheet content displaying available image formats in a list.
private struct SheetContent: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedImageFormat: FormatSelection
    private var close: () -> Void
    
    init(
        selectedImageFormat: Binding<FormatSelection>,
        close: @escaping () -> Void
    ) {
        self._selectedImageFormat = selectedImageFormat
        self.close = close
    }

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "section.lossyFormats")) {
                    ForEach(LossyImageFormat.allCases) { format in
                        FormatListEntry(
                            title: format.title,
                            subtitle: format.subtitle,
                            isSelected: selectedImageFormat.lossyImageFormat == format,
                            action: {
                                selectedImageFormat = .lossy(format)
                                close()
                            }
                        )
                    }
                }
                
                Section(String(localized: "section.losslessFormats")) {
                    ForEach(LosslessImageFormat.allCases) { format in
                        FormatListEntry(
                            title: format.title,
                            subtitle: format.subtitle,
                            isSelected: selectedImageFormat.losslessImageFormat == format,
                            action: {
                                selectedImageFormat = .lossless(format)
                                close()
                            }
                        )
                    }
                }
            }
            .navigationTitle(String(localized: "navigation.format"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(role: .close, action: close)
                    .controlSize(.small)
            }
        }
        .presentationBackground(Color(.systemBackground))
    }
}

/// A list entry for selecting an image format.
struct FormatListEntry: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(
            action: action
        ) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color(.label))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                }
                Spacer()
                Image(systemName: "checkmark")
                    .opacity(isSelected ? 1.0 : 0.0)
            }
        }
    }
}

private extension ButtonStyle where Self == CustomButtonStyle {
    static var custom: CustomButtonStyle {
        CustomButtonStyle()
    }
}

private struct CustomButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .contentShape(RoundedRectangle(cornerRadius: 10.0))
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                (colorScheme == .dark ? Color.white : Color.black)
                                    .opacity(configuration.isPressed ? 0.1 : 0)
                            )
                    }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.opaqueSeparator), lineWidth: 1.0)
            )
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    FormatPicker(
        selectedImageFormat: .constant(.lossless(.png)),
        selectedImageCompressionQuality: .constant(0.9)
    )
}
