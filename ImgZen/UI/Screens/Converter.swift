import OSLog
import SwiftUI
import StoreKit
import PhotosUI

/// The main entry point for the app.
/// Manages conversion flow, navigation, and review requests.
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
            // Each window converts into its own folder, so windows don't delete each other's results.
            let storageService = StorageService(
                baseDirectory: Constants.outputDirectory,
                subdirectoryName: UUID().uuidString
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
                                    requestReviewIfNeeded()
                                }
                            }

                            // Hide the progress if the stream ended without completing (e.g. cancellation).
                            progress = nil
                        }
                    },
                    onSendFeedback: { sheet = .mailComposer }
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
            // Confirms a finished conversion as the results slide in.
            .sensoryFeedback(.success, trigger: path.count) { old, new in new > old }
        }
    }

    /// Asks for a review with the system prompt after the third conversion, once the user has seen the app's value.
    /// The system decides whether to show it and limits how often it appears.
    private func requestReviewIfNeeded() {
        guard completedConversionsCount < 3 else { return }

        completedConversionsCount += 1
        if completedConversionsCount == 3 {
            requestReview()
        }
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
