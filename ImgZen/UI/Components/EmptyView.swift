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
        VStack(spacing: 20) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100)
                .cornerRadius(22.0703125)
            Text(String(localized: "label.readyToSelectImages"))
                .font(.body)
            VStack(spacing: 20) {
                Button(
                    String(localized: "button.addFromPhotoGallery"),
                    systemImage: "photo",
                    action: addFromPhotosAction
                )
                Button(
                    String(localized: "button.addFromFiles"),
                    systemImage: "folder",
                    action: addFromFilesAction
                )
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)
        }
    }
}
