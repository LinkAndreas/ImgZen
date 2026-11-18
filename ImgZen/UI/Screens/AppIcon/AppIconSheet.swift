import SwiftUI

/// The app icon picker as a sheet, opened from the More menu.
struct AppIconSheet: View {
    @Environment(\.dismiss) private var dismiss

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
        // A single row of icons: half height on iPhone, a centred form on iPad.
        .presentationDetents([.medium, .large])
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
