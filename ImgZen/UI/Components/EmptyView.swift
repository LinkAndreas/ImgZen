import SwiftUI

/// An empty state view shown when no images are selected, with options to add images.
struct EmptyView: View {
    private let addFromPhotosAction: () -> Void
    private let addFromFilesAction: () -> Void

    /// Creates an empty view.
    /// - Parameters:
    ///   - addFromPhotosAction: Action to open photo picker.
    ///   - addFromFilesAction: Action to open file picker.
    init(
        addFromPhotosAction: @escaping () -> Void,
        addFromFilesAction: @escaping () -> Void
    ) {
        self.addFromPhotosAction = addFromPhotosAction
        self.addFromFilesAction = addFromFilesAction
    }

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
        } actions: {
            // Photos is where most images come from, so it's the prominent choice.
            Button(action: addFromPhotosAction) {
                Label(String(localized: "button.addFromPhotoGallery"), systemImage: "photo.on.rectangle")
                    .frame(minWidth: 220)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)

            Button(action: addFromFilesAction) {
                Label(String(localized: "button.addFromFiles"), systemImage: "folder")
                    .frame(minWidth: 220)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
    }
}

#Preview {
    EmptyView(addFromPhotosAction: {}, addFromFilesAction: {})
}
