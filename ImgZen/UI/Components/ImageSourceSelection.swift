import PhotosUI
import SwiftUI

/// A prominent button with a menu for adding images from Photos or Files, in a toolbar or floating over content.
struct ImageSourceSelection: View {
    enum Style {
        /// An item in a toolbar, which the toolbar renders.
        case toolbar
        /// A prominent round button floating over content.
        case floating
        /// A round button floating over content next to a more prominent one.
        case floatingSecondary
    }

    private let style: Style
    private let addFromPhotosAction: () -> Void
    private let addFromFilesAction: () -> Void

    /// Creates an image source selection menu.
    /// - Parameters:
    ///   - style: Whether the button is a toolbar item or floats over content.
    ///   - addFromPhotosAction: Action to open photo picker.
    ///   - addFromFilesAction: Action to open file picker.
    init(
        style: Style = .toolbar,
        addFromPhotosAction: @escaping () -> Void,
        addFromFilesAction: @escaping () -> Void
    ) {
        self.style = style
        self.addFromPhotosAction = addFromPhotosAction
        self.addFromFilesAction = addFromFilesAction
    }

    var body: some View {
        switch style {
        case .toolbar:
            menu
                // The one prominent item of the bottom bar, as adding images is what the screen is for.
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
        case .floating:
            menu
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
        case .floatingSecondary:
            menu
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.large)
        }
    }

    private var menu: some View {
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
            // Icon and title, so a toolbar can show either, depending on the bar; floating, only the icon.
            switch style {
            case .toolbar:
                Label(String(localized: "button.addImages"), systemImage: "plus")
            case .floating, .floatingSecondary:
                Label(String(localized: "button.addImages"), systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .font(.title2.weight(.semibold))
                    .frame(minWidth: 28, minHeight: 28)
            }
        }
    }
}
