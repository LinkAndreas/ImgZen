import os
import SwiftUI

/// The supporter app icons. Supporters pick the icon ImgZen shows on the Home Screen;
/// everyone else sees the same icons locked, as a preview of what recurring support
/// includes.
struct SupporterIconsSection: View {
    let isUnlocked: Bool

    @Environment(AppIconStore.self) private var iconStore
    /// Goes up with every tap on a locked icon, to bounce its lock.
    @State private var lockedTapCount = 0

    var body: some View {
        Section {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(SupporterIcon.allCases) { icon in
                        SupporterIconTile(
                            icon: icon,
                            isSelected: icon == iconStore.current,
                            isLocked: !isUnlocked && icon != .classic,
                            lockedTapCount: lockedTapCount
                        ) {
                            select(icon)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
            .sensoryFeedback(.selection, trigger: iconStore.current)
            .sensoryFeedback(.impact(weight: .light), trigger: lockedTapCount)
        } header: {
            Text(String(localized: "support.supporterAppIcons"))
        } footer: {
            Text(String(localized: isUnlocked ? "support.thanksPickAnIcon" : "support.recurringSupportUnlocksIcons"))
        }
    }

    private func select(_ icon: SupporterIcon) {
        guard isUnlocked else {
            lockedTapCount += 1
            return
        }

        Task {
            do {
                try await iconStore.select(icon)
            } catch {
                logger.error("Failed to set the app icon to \(icon.rawValue): \(error)")
            }
        }
    }
}

/// One icon in the picker: its preview, its name, and a ring when it's the app's icon.
private struct SupporterIconTile: View {
    let icon: SupporterIcon
    let isSelected: Bool
    let isLocked: Bool
    let lockedTapCount: Int
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
                    .overlay(alignment: .bottomTrailing) {
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(5)
                                .background(.black.opacity(0.55), in: .circle)
                                .symbolEffect(.bounce, value: lockedTapCount)
                        }
                    }

                Text(icon.title)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
        }
        // Plain, so each icon is its own button rather than the whole row.
        .buttonStyle(.plain)
        .accessibilityLabel(Text(icon.title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isLocked ? Text(String(localized: "support.includedWithRecurringSupport")) : Text(verbatim: ""))
    }
}

#if DEBUG
#Preview("Locked") {
    Form {
        SupporterIconsSection(isUnlocked: false)
    }
    .environment(AppIconStore.preview())
}

#Preview("Unlocked") {
    Form {
        SupporterIconsSection(isUnlocked: true)
    }
    .environment(AppIconStore.preview())
}
#endif
