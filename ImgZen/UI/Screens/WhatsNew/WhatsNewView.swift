import SwiftUI

/// The release's new features, as a sheet: shown once after an update, and from Settings › About.
struct WhatsNewView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Shows where a feature can be tried; the sheet closes first.
    let onTry: (WhatsNew.Feature.Destination) -> Void
    let onDone: () -> Void
    /// Called once the sheet is on screen, so it isn't shown again.
    var onSeen: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                WhatsNewHeader()
                ForEach(WhatsNew.features) { feature in
                    WhatsNewFeatureRow(feature: feature, onTry: onTry)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 40)
            .padding(.bottom, 24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        // The button stays at the bottom edge, within thumb reach, like the onboarding's.
        .safeAreaInset(edge: .bottom) {
            Button(action: onDone) {
                Text(String(localized: "whatsNew.continue"))
                    .frame(maxWidth: horizontalSizeClass == .regular ? 350 : .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background { AppBackground() }
        .onAppear(perform: onSeen)
    }
}

#if DEBUG
#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            WhatsNewView(onTry: { _ in }, onDone: {})
                .presentationSizing(.form)
        }
        .environment(AppIconStore.preview())
}
#endif
