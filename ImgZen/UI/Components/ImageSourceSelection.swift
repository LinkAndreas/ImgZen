import PhotosUI
import SwiftUI

/// A prominent toolbar button with a menu for adding images from Photos or Files.
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
            // Icon and title, so the system can show either, depending on the bar.
            Label(String(localized: "button.addImages"), systemImage: "plus")
        }
        // The one prominent item of the bottom bar, as adding images is what the screen is for.
        .buttonStyle(.borderedProminent)
        .tint(.accentColor)
    }
}
