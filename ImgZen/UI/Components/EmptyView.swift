import SwiftUI

/// An empty state view shown when no images are selected.
/// The actions to add images sit in the bar at the bottom edge, where they're easier to reach.
///
/// A plain layout in the style of `ContentUnavailableView`, which brings its own scroll view:
/// laid over the gallery, that one could take over the navigation bar's scroll tracking,
/// so the large title wouldn't collapse with the gallery once images are added.
struct EmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 88)
                .padding(.bottom, 4)
                .accessibilityHidden(true)

            Text(String(localized: "label.readyToSelectImages"))
                .font(.title2.bold())

            Text(String(localized: "label.emptyStateDescription"))
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .frame(maxWidth: 440)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    EmptyView()
}
