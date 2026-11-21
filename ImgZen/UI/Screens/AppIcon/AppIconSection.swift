import os
import SwiftUI

/// The app icons to pick the one ImgZen shows on the Home Screen. The app takes its logo and colors
/// from the icon, and changes with it.
struct AppIconSection: View {
    @Environment(AppIconStore.self) private var iconStore

    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top), count: 4)

    var body: some View {
        Section {
            // Every icon at once, in two rows of four, rather than a row that hides half of them off the edge.
            LazyVGrid(columns: Self.columns, alignment: .center, spacing: 14) {
                ForEach(AppIcon.allCases) { icon in
                    AppIconTile(icon: icon, isSelected: icon == iconStore.current) {
                        select(icon)
                    }
                }
            }
            .padding(.vertical, 6)
            .sensoryFeedback(.selection, trigger: iconStore.current)
        } header: {
            Text(String(localized: "button.appIcon"))
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
