import OSLog
import SwiftUI
import StoreKit
import PhotosUI

/// The main entry point for the app.
/// Manages conversion flow, navigation, and review requests.
struct Converter: View {
    /// The images of a finished conversion, shown in a sheet to review and share.
    struct Results: Identifiable {
        let id = UUID()
        let items: [OutputItem]
    }

    /// Enum representing currently presented sheets (modals).
    enum Sheet {
        case supportTheDeveloper
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
    @State private var results: Results?
    @State private var sheet: Sheet?
    @State private var conversionFailure: ConversionFailure?
    @State private var inputService = InputService()
    @State private var selectedImageFormat: FormatSelection = .lossy(.jpeg)
    @State private var selectedImageCompressionQuality: ImageCompressionQuality = 0.9
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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
            // Whether bars are vertical comes from the environment (iPhone Duo), and decides where the settings go.
            VerticalBarReader { usesVerticalBars in
                let isInspectorShown = isInspectorLayout(usesVerticalBars: usesVerticalBars)
                    && !inputService.items.isEmpty
                NavigationStack {
                    InputView(
                        inputService: inputService,
                        selectedImageFormat: $selectedImageFormat,
                        selectedImageCompressionQuality: $selectedImageCompressionQuality,
                        areSettingsShownInline: isInspectorShown,
                        previewLoader: previewLoader,
                        fileURLFor: fileURLResolver.fileURL(for:),
                        onConvert: { items, imageFormat in
                            // Only one conversion at a time: the keyboard shortcut still works behind the progress card.
                            guard progress == nil else { return }
                            progress = .indeterminate
                            let startedAt = ContinuousClock.now

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
                                        // The card stays long enough to follow, even when converting is quick,
                                        // and then confirms it's done before the results open.
                                        try await Task.sleep(until: startedAt + .seconds(1.2), clock: .continuous)
                                        progress = .amount(current: items.count, total: items.count)
                                        try await Task.sleep(for: .seconds(1.5))
                                        let failedCount = items.count - outputItems.count

                                        // Without any converted image there's nothing to share, so stay and explain instead.
                                        guard !outputItems.isEmpty else {
                                            progress = nil
                                            conversionFailure = ConversionFailure(failedCount: failedCount, totalCount: items.count)
                                            return
                                        }

                                        // The card fades as the results slide up over the images they came from.
                                        progress = nil
                                        results = Results(items: outputItems)

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
                        onSupportTheDeveloper: { sheet = .supportTheDeveloper },
                        onSendFeedback: { sheet = .mailComposer }
                    )
                }
                // The inspector is a column next to the navigation stack rather than inside it, so the stack's
                // navigation bar, and the title it shows when the large title collapses, spans only the gallery.
                // It shows once there are images to convert.
                .formatInspector(isShown: isInspectorShown) {
                    FormatInspector(
                        selectedImageFormat: $selectedImageFormat,
                        selectedImageCompressionQuality: $selectedImageCompressionQuality
                    )
                    .inspectorColumnWidth(min: 300, ideal: 340, max: 420)
                }
            }
            .sheet(isPresented: $sheet.isSupportTheDeveloperPresented) {
                SupportSheet()
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
            // The results are a self-contained task on top of the images: reviewed, shared, and closed,
            // returning to the images and settings as they were.
            .sheet(item: $results) { results in
                NavigationStack {
                    OutputView(
                        items: results.items,
                        previewLoader: previewLoader
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(role: .close) {
                                self.results = nil
                            }
                        }
                    }
                }
                // Images that couldn't be converted are reported on the results: an alert from the screen
                // behind the sheet wouldn't show while the sheet is open.
                .conversionFailureAlert($conversionFailure)
                // Room for the gallery on iPad; full height on iPhone.
                .presentationSizing(.page)
            }
            // Confirms a finished conversion as the results slide in.
            .sensoryFeedback(.success, trigger: results?.id) { _, new in new != nil }
            // A conversion without any converted image has no results, so it's reported here instead.
            .conversionFailureAlert(Binding(
                get: { results == nil ? conversionFailure : nil },
                set: { conversionFailure = $0 }
            ))
        }
    }

    /// Whether the settings show in an inspector column next to the gallery instead of behind the format button:
    /// on iPad in regular width, and on iPhone in regular width with vertical bars, which is iPhone Duo unfolded
    /// in landscape. In portrait, the unfolded display uses horizontal bars and has no room for a column beside
    /// the gallery, so the format button and its sheet are used there.
    /// - Parameter usesVerticalBars: Whether the system shows the bars vertically (iPhone Duo).
    private func isInspectorLayout(usesVerticalBars: Bool) -> Bool {
        guard horizontalSizeClass == .regular else { return false }

        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return true
        case .phone:
            return usesVerticalBars
        default:
            return false
        }
    }

    fileprivate static func alertTitle(for failure: ConversionFailure) -> String {
        failure.isComplete
            ? String(localized: "alert.conversionFailed.title")
            : String(localized: "alert.conversionPartiallyFailed.title")
    }

    fileprivate static func alertMessage(for failure: ConversionFailure) -> String {
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
    /// Returns true if the Support the Developer sheet should be presented.
    var isSupportTheDeveloperPresented: Bool {
        get {
            if case .supportTheDeveloper = self {
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

private extension View {
    /// Adds the format inspector only while `isShown`: attached while hidden, its column showed for a moment
    /// at launch before it collapsed for the empty state.
    @ViewBuilder
    func formatInspector<Content: View>(
        isShown: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if isShown {
            inspector(isPresented: .constant(true), content: content)
        } else {
            self
        }
    }
}

private extension View {
    /// Explains images of a finished conversion that couldn't be converted.
    func conversionFailureAlert(_ failure: Binding<Converter.ConversionFailure?>) -> some View {
        alert(
            failure.wrappedValue.map(Converter.alertTitle(for:)) ?? "",
            isPresented: Binding(
                get: { failure.wrappedValue != nil },
                set: { if !$0 { failure.wrappedValue = nil } }
            ),
            presenting: failure.wrappedValue
        ) { _ in
            Button(String(localized: "button.ok"), role: .cancel) {}
        } message: { failure in
            Text(Converter.alertMessage(for: failure))
        }
    }
}
