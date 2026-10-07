import SwiftUI

/// An empty state view shown when no images are selected.
/// The actions to add images sit in the bar at the bottom edge, where they're easier to reach.
struct EmptyView: View {
    var body: some View {
        ContentUnavailableView {
            Label {
                Text(String(localized: "label.readyToSelectImages"))
            } icon: {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 88)
                    .accessibilityHidden(true)
            }
        } description: {
            Text(String(localized: "label.emptyStateDescription"))
        }
    }
}

#Preview {
    EmptyView()
}
