import Foundation
import SwiftUI
import PhotosUI

/// Extension providing image picker functionality via PHPickerViewController.
extension View {
    /// Presents an image picker sheet that allows selecting images from the photo library.
    /// - Parameters:
    ///   - isPresented: Binding that controls sheet presentation.
    ///   - selectionLimit: Maximum number of images that can be selected. 0 means unlimited.
    ///   - completion: Closure called with selected InputItems when selection completes.
    /// - Returns: A view with the image picker modifier applied.
    func imagePicker(
        isPresented: Binding<Bool>,
        selectionLimit: Int = 0,
        completion: @escaping ([InputItem]) -> Void
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            PHPicker(
                selectionLimit: selectionLimit,
                completion: completion
            )
        }
    }
}

/// Internal wrapper for PHPickerViewController.
fileprivate struct PHPicker: UIViewControllerRepresentable {
    let selectionLimit: Int
    let completion: ([InputItem]) -> Void

    init(
        selectionLimit: Int,
        completion: @escaping ([InputItem]) -> Void
    ) {
        self.selectionLimit = selectionLimit
        self.completion = completion
    }

    /// Creates and configures the PHPickerViewController.
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = selectionLimit
        configuration.filter = .images
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> PhotoPickerCoordinator {
        PhotoPickerCoordinator(completion: completion)
    }
}

/// Coordinator that handles PHPickerViewController delegate callbacks.
fileprivate final class PhotoPickerCoordinator: PHPickerViewControllerDelegate {
    let completion: ([InputItem]) -> Void
    let destination = URL.applicationSupportDirectory
        .appending(path: "imports", directoryHint: .isDirectory)

    init(completion: @escaping ([InputItem]) -> Void) {
        self.completion = completion
    }

    /// Handles the completion of image selection from the picker.
    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        picker.dismiss(animated: true)

        completion(results.map { result in
            InputItem(
                source: .fileURLHandler(handler: { action in
                    result.itemProvider.loadFileRepresentation(
                        forTypeIdentifier: UTType.image.identifier
                    ) { url, error in
                        if let url {
                            action(url)
                        }
                    }
                })
            )
        })
    }
}

/// Extension providing async file representation loading for NSItemProvider.
extension NSItemProvider {
    /// Asynchronously loads a file representation for the given type identifier.
    /// - Parameter typeIdentifier: The UTI type identifier (e.g., "public.image").
    /// - Returns: A temporary file URL containing the loaded data.
    /// - Throws: Errors if loading fails.
    func loadFileRepresentation(
        forTypeIdentifier typeIdentifier: String
    ) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                if let error {
                    return continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NSError(domain: "unknown", code: 42))
                }
            }
        }
    }
}
