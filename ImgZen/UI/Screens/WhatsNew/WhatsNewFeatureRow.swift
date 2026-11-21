import SwiftUI

/// One new feature: its symbol in the app icon's color, what it is, and a button to try it.
struct WhatsNewFeatureRow: View {
    let feature: WhatsNew.Feature
    let onTry: (WhatsNew.Feature.Destination) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: feature.systemImage)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 40)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.text)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let destination = feature.destination {
                    Button(String(localized: destination.title)) { onTry(destination) }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.borderless)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 24) {
        ForEach(WhatsNew.features) { feature in
            WhatsNewFeatureRow(feature: feature, onTry: { _ in })
        }
    }
    .padding()
}
#endif
