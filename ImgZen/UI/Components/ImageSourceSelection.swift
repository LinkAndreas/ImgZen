import PhotosUI
import SwiftUI

/// A menu button for selecting image sources (Photos or Files).
struct ImageSourceSelection: View {
    private let addFromPhotosAction: () -> Void
    private let addFromFilesAction: () -> Void

    /// Creates an image source selection menu.
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
        Menu {
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
        } label: {
            Label("", systemImage: "plus")
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}
