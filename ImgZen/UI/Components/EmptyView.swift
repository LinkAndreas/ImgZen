import SwiftUI

/// An empty state view shown when no images are selected, with the choices of where to add them from.
///
/// A plain layout in the style of `ContentUnavailableView`, which brings its own scroll view:
/// laid over the gallery, that one could take over the navigation bar's scroll tracking.
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
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                AppLogo(size: 88)
                    .padding(.bottom, 4)

                Text(String(localized: "label.readyToSelectImages"))
                    .font(.title2.bold())

                Text(String(localized: "label.emptyStateDescription"))
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)

            // Photos is where most images come from, so it's the prominent choice.
            VStack(spacing: 12) {
                Button(action: addFromPhotosAction) {
                    Label(String(localized: "button.addFromPhotoGallery"), systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)

                Button(action: addFromFilesAction) {
                    Label(String(localized: "button.addFromFiles"), systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
            }
            .controlSize(.large)
            .frame(maxWidth: 280)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: 440)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyView(addFromPhotosAction: {}, addFromFilesAction: {})
        .environment(AppIconStore.preview())
}
