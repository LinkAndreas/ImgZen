import SwiftUI

/// The toolbar button showing what the images become, e.g. "JPEG 90%", which opens the format settings.
/// In the vertical bar of iPhone Duo, the same details stack within the bar's width.
struct FormatToolbarButton: View {
    let selectedImageFormat: FormatSelection
    let selectedImageCompressionQuality: ImageCompressionQuality
    let action: () -> Void

    private var formattedQuality: String {
        selectedImageCompressionQuality.formatted(.percent.precision(.fractionLength(0)))
    }

    var body: some View {
        Button(action: action) {
            VerticalBarReader { isVertical in
                if isVertical {
                    VStack(spacing: 2) {
                        Image(systemName: "photo")
                        Text(selectedImageFormat.title)
                            .font(.caption2.weight(.semibold))
                        if selectedImageFormat.isLossy {
                            Text(formattedQuality)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        Text(selectedImageFormat.title)
                            .fontWeight(.semibold)
                        if selectedImageFormat.isLossy {
                            Text(formattedQuality)
                                .foregroundStyle(.secondary)
                        }
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .lineLimit(1)
            .monospacedDigit()
            .contentTransition(.numericText(value: selectedImageCompressionQuality))
            .animation(.smooth(duration: 0.2), value: selectedImageCompressionQuality)
        }
        .accessibilityLabel(String(localized: "label.destinationFormat"))
        .accessibilityValue(
            selectedImageFormat.isLossy
                ? "\(selectedImageFormat.title), \(formattedQuality)"
                : selectedImageFormat.title
        )
    }
}

/// The screen's confirming action: its title in a horizontal bar, its symbol in a vertical one,
/// where a title wouldn't fit the bar's width.
struct ConvertToolbarButton: View {
    let action: () -> Void

    var body: some View {
        Button(role: .confirm, action: action) {
            VerticalBarReader { isVertical in
                if isVertical {
                    Label(String(localized: "button.convert"), systemImage: "arrow.triangle.2.circlepath")
                        .labelStyle(.iconOnly)
                } else {
                    Text(String(localized: "button.convert"))
                }
            }
        }
        .keyboardShortcut(.return, modifiers: .command)
    }
}
