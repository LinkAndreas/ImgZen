import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Extension providing a file picker via UIDocumentPickerViewController.
extension View {
    /// Presents a document picker sheet for opening files.
    /// Unlike `fileImporter`, the sheet's content is accessible, so it can be configured like any other sheet.
    /// - Parameters:
    ///   - isPresented: Binding that controls sheet presentation.
    ///   - allowedContentTypes: The types of files that can be selected.
    ///   - allowsMultipleSelection: Whether several files can be selected.
    ///   - completion: Closure called with the selected, security-scoped file URLs.
    /// - Returns: A view with the document picker modifier applied.
    func documentPicker(
        isPresented: Binding<Bool>,
        allowedContentTypes: [UTType],
        allowsMultipleSelection: Bool = true,
        completion: @escaping ([URL]) -> Void
    ) -> some View {
        sheet(isPresented: isPresented) {
            DocumentPicker(
                allowedContentTypes: allowedContentTypes,
                allowsMultipleSelection: allowsMultipleSelection,
                completion: { urls in
                    isPresented.wrappedValue = false
                    completion(urls)
                }
            )
            .ignoresSafeArea()
            .toolbarStaysInTopBar()
        }
    }
}

/// Internal wrapper for UIDocumentPickerViewController.
fileprivate struct DocumentPicker: UIViewControllerRepresentable {
    let allowedContentTypes: [UTType]
    let allowsMultipleSelection: Bool
    let completion: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes)
        picker.allowsMultipleSelection = allowsMultipleSelection
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> DocumentPickerCoordinator {
        DocumentPickerCoordinator(completion: completion)
    }
}

/// Coordinator that handles UIDocumentPickerViewController delegate callbacks.
fileprivate final class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
    let completion: ([URL]) -> Void

    init(completion: @escaping ([URL]) -> Void) {
        self.completion = completion
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        completion(urls)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion([])
    }
}
