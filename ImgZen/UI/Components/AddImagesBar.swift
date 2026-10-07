import SwiftUI

/// The bottom bar shown while no images are selected, offering where to add them from.
/// Photos, the most common source, is the prominent button on the trailing side, closest to the thumb.
struct AddImagesBar: View {
    private let addFromPhotosAction: () -> Void
    private let addFromFilesAction: () -> Void

    /// Creates the bar.
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
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: addFromFilesAction) {
                    Label(String(localized: "button.files"), systemImage: "folder")
                }
                .buttonStyle(.glass)

                Button(action: addFromPhotosAction) {
                    Label(String(localized: "button.photos"), systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            }
            .controlSize(.large)
            .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: 600)
    }
}

#Preview {
    Color.clear
        .safeAreaBar(edge: .bottom) {
            AddImagesBar(addFromPhotosAction: {}, addFromFilesAction: {})
        }
}
