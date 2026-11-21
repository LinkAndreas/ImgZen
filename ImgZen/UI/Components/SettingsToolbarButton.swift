import SwiftUI

/// The gear in the main screen's toolbar that opens the settings. An icon on every bar, so it fits
/// the vertical bar of iPhone Duo too, with "Settings" for VoiceOver and in the overflow menu.
struct SettingsToolbarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(String(localized: "settings.title"), systemImage: "gearshape")
                .labelStyle(.iconOnly)
        }
        .keyboardShortcut(",", modifiers: .command)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        Color.clear
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton {}
                }
            }
    }
}
#endif
