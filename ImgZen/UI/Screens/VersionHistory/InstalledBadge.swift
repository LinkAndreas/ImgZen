import SwiftUI

/// A subtle mark on the version running on the device, in the app icon's color.
struct InstalledBadge: View {
    var body: some View {
        Text(String(localized: "versionHistory.installed"))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(.tint.opacity(0.14), in: .capsule)
    }
}

#if DEBUG
#Preview {
    InstalledBadge()
        .padding()
        .environment(AppIconStore.preview())
}
#endif
