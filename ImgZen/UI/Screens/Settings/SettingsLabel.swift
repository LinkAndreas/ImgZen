import SwiftUI

/// A settings row's label: its symbol in the app icon's color, its title in the label color.
struct SettingsLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label {
            // Explicit label color: inside a button or link, the hierarchical styles resolve to the tint color.
            Text(title)
                .foregroundStyle(Color(.label))
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
        }
    }
}

#if DEBUG
#Preview {
    Form {
        SettingsLabel(title: "Version History", systemImage: "clock.arrow.circlepath")
        SettingsLabel(title: "Send Feedback", systemImage: "envelope")
    }
    .environment(AppIconStore.preview())
}
#endif
