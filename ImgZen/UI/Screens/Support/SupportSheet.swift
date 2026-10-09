import SwiftUI

/// Support the Developer as a sheet, opened from the More menu.
struct SupportSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SupportView()
                .navigationTitle(String(localized: "button.supportTheDeveloper"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        // The system close button: an ✕ with the localized "Close" label.
                        Button(role: .close) { dismiss() }
                    }
                }
        }
        // A centred form on iPad rather than a full-height page.
        .presentationSizing(.form)
    }
}

#if DEBUG
#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            SupportSheet()
        }
        .environment(SupportStore(service: PreviewSupportService()))
        .environment(AppIconStore.preview())
}
#endif
