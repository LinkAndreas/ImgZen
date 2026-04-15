import SwiftUI
import StoreKit
import PhotosUI

/// The main entry point for the app.
/// Manages conversion flow, navigation, and feedback prompts.
struct Converter: View {
    /// Enum representing navigation destinations for the main navigation stack.
    enum Destination: Hashable {
        case output([OutputItem])
    }

    /// Enum representing currently presented sheets (modals).
    enum Sheet {
        case mailComposer
    }

    @State private var progress: ProgressBar.State?
    @State private var conversion: Task<Void, Error>?
    @State private var path: [Destination] = []
    @State private var sheet: Sheet?
    @Environment(\.requestReview) private var requestReview
    @AppStorage("completedConversionsCount") var completedConversionsCount = 0

    /// The main application view structure. Sets up dependency context and manages navigation.
    var body: some View {
        WithContext {
            let fileURLResolver = FileURLResolver()
            let imageService = ImageService(
                imageRepository: ImageFromURLRepository()
            )
            let storageService = StorageService(
                baseDirectory: .applicationSupportDirectory,
                subdirectoryName: "output"
            )
            let conversionService = ImageConversionService(
                metadata: imageService.metadata(for:),
                imageData: imageService.imageData(for:resolution:),
                fileURLFor: fileURLResolver.fileURL(for:),
                prepareOutputDirectory: {
                    try storageService.prepareDirectory()
                },
                writeData: { data, filename in
                    try storageService.write(data, filename: filename)
                },
                convert: ImageConverter.convertImageData(_:to:)
            )
            return (fileURLResolver, imageService, conversionService)
        } content: { fileURLResolver, imageService, conversionService in
            NavigationStack(path: $path) {
                InputView(
                    imageData: imageService.imageData(for:resolution:),
                    metadata: imageService.metadata(for:),
                    fileURLFor: fileURLResolver.fileURL(for:),
                    onConvert: { items, imageFormat in
                        conversion = Task {
                            for await event in try conversionService.convert(
                                items: items,
                                imageFormat: imageFormat
                            ) {
                                switch event {
                                case .started:
                                    progress = .amount(current: 0, total: items.count)
                                case let .converting(completed, total):
                                    progress = .amount(current: completed, total: total)
                                case let .completed(items):
                                    progress = .amount(current: items.count, total: items.count)
                                    try await Task.sleep(for: .seconds(1.0))
                                    path.append(.output(items))
                                    try await Task.sleep(for: .seconds(0.3))
                                    progress = nil
                                    try await Task.sleep(for: .seconds(0.75))
                                    showInAppRatingIfNeeded()
                                }
                            }
                        }
                    }
                )
                .navigationDestination(for: Destination.self) { destination in
                    switch destination {
                    case let .output(items):
                        OutputView(
                            items: items,
                            imageData: imageService.imageData(for:resolution:),
                            metadata: imageService.metadata(for:)
                        )
                    }
                }
            }
            .mailComposer(
                isPresenting: $sheet.isMailComposerPresented,
                recipients: ["imgzen@linkandreas.de"],
                subject: String(localized: "mail.feedbackSubject"),
                body: String(localized: "mail.feedbackBody")
            )
            .fullScreenProgressBar(
                title: String(localized: "progress.imageConversion"),
                subtitle: String(localized: "progress.convertingImages"),
                progress: progress,
                onCancel: {
                    conversion?.cancel()
                    progress = nil
                }
            )
        }
    }

    /// Triggers in-app rating prompt or increments process count after each conversion.
    private func showInAppRatingIfNeeded() {
        if completedConversionsCount < 3 {
            completedConversionsCount += 1
        }

        if completedConversionsCount == 3 {
            completedConversionsCount += 1
            requestFeedback()
        }
    }

    /// Presents the feedback window for the user to send feedback email or rate positively.
    private func requestFeedback() {
        WindowManager.shared.present(
            InAppRatingWindowContent(
                likeButtonAction: {
                    WindowManager.shared.dismiss {
                        requestReview()
                    }
                },
                dislikeButtonAction: {
                    WindowManager.shared.dismiss {
                        sheet = .mailComposer
                    }
                }
            )
        )
    }
}

/// Extension to help present sheets in ContentView using optional Sheet binding.
extension Converter.Sheet? {
    /// Returns true if the mail composer sheet should be presented.
    var isMailComposerPresented: Bool {
        get {
            if case .mailComposer = self {
                return true
            } else {
                return false
            }
        }

        set {
            if !newValue {
                self = nil
            }
        }
    }
}
