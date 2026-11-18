import os
import SwiftUI

/// The app icons to pick the one ImgZen shows on the Home Screen. The app takes its logo and colors
/// from the icon, and changes with it.
struct AppIconSection: View {
    @Environment(AppIconStore.self) private var iconStore

    var body: some View {
        Section {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(AppIcon.allCases) { icon in
                        AppIconTile(icon: icon, isSelected: icon == iconStore.current) {
                            select(icon)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
            .sensoryFeedback(.selection, trigger: iconStore.current)
        } footer: {
            Text(String(localized: "appIcon.pickAnIcon"))
        }
    }

    private func select(_ icon: AppIcon) {
        Task {
            do {
                try await iconStore.select(icon)
            } catch {
                logger.error("Failed to set the app icon to \(icon.rawValue): \(error)")
            }
        }
    }
}

#if DEBUG
#Preview {
    Form {
        AppIconSection()
    }
    .environment(AppIconStore.preview())
}
#endif
