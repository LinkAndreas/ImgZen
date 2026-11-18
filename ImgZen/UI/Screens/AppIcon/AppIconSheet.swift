import SwiftUI

/// The app icon picker as a sheet, opened from the More menu.
struct AppIconSheet: View {
    @Environment(\.dismiss) private var dismiss

    private static var detents: Set<PresentationDetent> {
        UIDevice.current.userInterfaceIdiom == .pad ? [.large] : [.medium, .large]
    }

    var body: some View {
        NavigationStack {
            Form {
                AppIconSection()
            }
            .scrollContentBackground(.hidden)
            .background { AppBackground() }
            .navigationTitle(String(localized: "button.appIcon"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // The system close button: an ✕ with the localized "Close" label.
                    Button(role: .close) { dismiss() }
                }
            }
        }
        // Two rows of icons fit in half height on iPhone. On iPad, detents would pin the sheet to the bottom
        // edge, so it stays a centred form there.
        .presentationDetents(Self.detents)
        .presentationSizing(.form)
    }
}

#if DEBUG
#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            AppIconSheet()
        }
        .environment(AppIconStore.preview())
}
#endif
