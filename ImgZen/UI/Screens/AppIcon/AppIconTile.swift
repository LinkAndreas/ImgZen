import SwiftUI

/// One icon in the picker: its preview, its name, and a ring when it's the app's icon.
struct AppIconTile: View {
    let icon: AppIcon
    let isSelected: Bool
    let action: () -> Void

    private static let size: CGFloat = 60
    /// The Home Screen's corner shape, scaled to the preview.
    private static let shape = RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(icon.previewImageName)
                    .resizable()
                    .frame(width: Self.size, height: Self.size)
                    .clipShape(Self.shape)
                    .overlay {
                        Self.shape.strokeBorder(.separator, lineWidth: 0.5)
                    }
                    .padding(4)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: Self.size * 0.225 + 4, style: .continuous)
                                .strokeBorder(.tint, lineWidth: 2.5)
                        }
                    }

                Text(icon.title)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    // Long names, such as "Mitternachtsgold", shrink a little to fit the grid column.
                    .minimumScaleFactor(0.7)
            }
        }
        // Plain, so each icon is its own button rather than the whole row.
        .buttonStyle(.plain)
        .accessibilityLabel(Text(icon.title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
#Preview {
    HStack {
        AppIconTile(icon: .classic, isSelected: true) {}
        AppIconTile(icon: .ember, isSelected: false) {}
    }
    .environment(AppIconStore.preview())
}
#endif
