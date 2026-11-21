import SwiftUI

/// Shows the latest release's new features again, as after an update.
struct WhatsNewRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsLabel(title: String(localized: "settings.whatsNew"), systemImage: "sparkles")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
    }
}

#if DEBUG
#Preview {
    Form {
        WhatsNewRow {}
    }
    .environment(AppIconStore.preview())
}
#endif
