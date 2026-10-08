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

    /// Images of a finished conversion that couldn't be converted.
    struct ConversionFailure {
        let failedCount: Int
        let totalCount: Int

        var isComplete: Bool {
            failedCount == totalCount
        }
    }

    @State private var progress: ProgressBar.State?
    @State private var conversion: Task<Void, Error>?
    @State private var path: [Destination] = []
    @State private var sheet: Sheet?
    @State private var conversionFailure: ConversionFailure?
    @Environment(\.requestReview) private var requestReview
    @AppStorage("completedConversionsCount") var completedConversionsCount = 0

    /// The main application view structure. Sets up dependency context and manages navigation.
    var body: some View {
        WithContext {
            let fileURLResolver = FileURLResolver()
            // Reads files off the main actor, for previews and conversions alike.
            let imageRepository = ImageFromURLRepository()
            // Each window converts into its own folder, so windows don't delete each other's results.
            let storageService = StorageService(
                baseDirectory: Constants.outputDirectory,
                subdirectoryName: UUID().uuidString
            )
            let conversionService = ImageConversionService(
                metadata: { @concurrent url in
                    try imageRepository.metadata(for: url)
                },
                imageData: { @concurrent url, resolution in
                    try await imageRepository.image(for: url, resolution: resolution)
                },
                fileURLFor: fileURLResolver.fileURL(for:),
                prepareOutputDirectory: {
                    try storageService.prepareDirectory()
                },
                writeData: { data, filename in
                    try storageService.write(data, filename: filename)
                },
                convert: ImageConverter.convertImageData(_:to:)
            )
            // Shared by both galleries, so previews of converted images stay cached when going back and forth.
            let previewLoader = ImagePreviewLoader(repository: imageRepository)
            return (fileURLResolver, conversionService, previewLoader)
        } content: { fileURLResolver, conversionService, previewLoader in
            NavigationStack(path: $path) {
                InputView(
                    previewLoader: previewLoader,
                    fileURLFor: fileURLResolver.fileURL(for:),
                    onConvert: { items, imageFormat in
                        // Only one conversion at a time: the keyboard shortcut still works behind the progress card.
                        guard progress == nil else { return }
                        progress = .indeterminate

                        conversion = Task {
                            let events: AsyncStream<ImageConversionService.Event>
                            do {
                                events = try conversionService.convert(
                                    items: items,
                                    imageFormat: imageFormat
                                )
                            } catch {
                                logger.error("Failed to start conversion: \(error)")
                                progress = nil
                                conversionFailure = ConversionFailure(failedCount: items.count, totalCount: items.count)
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
                                    let failedCount = items.count - outputItems.count

                                    // Without any converted image there's nothing to share, so stay and explain instead.
                                    guard !outputItems.isEmpty else {
                                        progress = nil
                                        conversionFailure = ConversionFailure(failedCount: failedCount, totalCount: items.count)
                                        return
                                    }

                                    path.append(.output(outputItems))
                                    try await Task.sleep(for: .seconds(0.3))
                                    progress = nil

                                    if failedCount > 0 {
                                        conversionFailure = ConversionFailure(failedCount: failedCount, totalCount: items.count)
                                    } else {
                                        try await Task.sleep(for: .seconds(0.75))
                                        requestReviewIfNeeded()
                                    }
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
                            previewLoader: previewLoader
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
                completedSubtitle: String(localized: "progress.completed"),
                progress: progress,
                onCancel: {
                    conversion?.cancel()
                    progress = nil
                }
            )
            // Confirms a finished conversion as the results slide in.
            .sensoryFeedback(.success, trigger: path.count) { old, new in new > old }
            .alert(
                conversionFailure.map(Self.alertTitle(for:)) ?? "",
                isPresented: Binding(
                    get: { conversionFailure != nil },
                    set: { if !$0 { conversionFailure = nil } }
                ),
                presenting: conversionFailure
            ) { _ in
                Button(String(localized: "button.ok"), role: .cancel) {}
            } message: { failure in
                Text(Self.alertMessage(for: failure))
            }
        }
    }

    private static func alertTitle(for failure: ConversionFailure) -> String {
        failure.isComplete
            ? String(localized: "alert.conversionFailed.title")
            : String(localized: "alert.conversionPartiallyFailed.title")
    }

    private static func alertMessage(for failure: ConversionFailure) -> String {
        failure.isComplete
            ? String(localized: "alert.conversionFailed.message")
            : String(format: String(localized: "alert.conversionPartiallyFailed.message"), failure.failedCount, failure.totalCount)
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
