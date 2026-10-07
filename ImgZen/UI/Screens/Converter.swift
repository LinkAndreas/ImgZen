import OSLog
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
    @State private var isRatingPromptVisible = false
    @Environment(\.requestReview) private var requestReview
    @AppStorage("completedConversionsCount") var completedConversionsCount = 0

    /// The main application view structure. Sets up dependency context and manages navigation.
    var body: some View {
        WithContext {
            let fileURLResolver = FileURLResolver()
            fileURLResolver.removeCachedFiles()
            // Picked photos were copied here before 1.1.0 and never cleaned up.
            try? FileManager.default.removeItem(at: .applicationSupportDirectory.appending(path: "input"))
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
                            let events: AsyncStream<ImageConversionService.Event>
                            do {
                                events = try conversionService.convert(
                                    items: items,
                                    imageFormat: imageFormat
                                )
                            } catch {
                                logger.error("Failed to start conversion: \(error)")
                                return
                            }

                            for await event in events {
                                switch event {
                                case .started:
                                    progress = .amount(current: 0, total: items.count)
                                case let .converting(completed, total):
                                    progress = .amount(current: completed, total: total)
                                case let .completed(outputItems):
                                    try await Task.sleep(for: .seconds(1.0))
                                    path.append(.output(outputItems))
                                    try await Task.sleep(for: .seconds(0.3))
                                    progress = nil
                                    try await Task.sleep(for: .seconds(0.75))
                                    showInAppRatingIfNeeded()
                                }
                            }

                            // Hide the progress if the stream ended without completing (e.g. cancellation).
                            progress = nil
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
                recipients: ["feedback@linkandreas.de"],
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
            .overlay {
                // Presented inside this scene, so it follows the window when it resizes or another window is open.
                if isRatingPromptVisible {
                    InAppRatingWindowContent(
                        likeButtonAction: {
                            isRatingPromptVisible = false
                            requestReview()
                        },
                        dislikeButtonAction: {
                            isRatingPromptVisible = false
                            sheet = .mailComposer
                        }
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .animation(.smooth(duration: 0.25), value: isRatingPromptVisible)
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

    /// Presents the feedback prompt for the user to send feedback email or rate positively.
    private func requestFeedback() {
        isRatingPromptVisible = true
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
