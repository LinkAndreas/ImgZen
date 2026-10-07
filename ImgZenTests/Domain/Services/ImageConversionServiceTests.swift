import Foundation
import Testing
@testable import ImgZen

struct ImageConversionServiceTests {
    
    @Test("ImageConversionService should emit started event")
    func testStartedEvent() async throws {
        let service = createService()
        let items = [createInputItem()]
        
        let stream = try service.convert(items: items, imageFormat: .lossless(.png))
        
        var events: [ImageConversionService.Event] = []
        for await event in stream {
            events.append(event)
            if case .completed = event {
                break
            }
        }
        
        #expect(events.first == .started)
    }
    
    @Test("ImageConversionService should emit converting events with progress")
    func testConvertingEvents() async throws {
        let service = createService()
        let items = [
            createInputItem(),
            createInputItem(),
            createInputItem()
        ]
        
        let stream = try service.convert(items: items, imageFormat: .lossless(.png))
        
        var convertingEvents: [ImageConversionService.Event] = []
        for await event in stream {
            if case .converting = event {
                convertingEvents.append(event)
            }
            if case .completed = event {
                break
            }
        }
        
        #expect(convertingEvents.count == 3)
        
        if case .converting(let completed1, let total1) = convertingEvents[0] {
            #expect(completed1 == 1)
            #expect(total1 == 3)
        } else {
            Issue.record("Expected converting event")
        }
        
        if case .converting(let completed2, let total2) = convertingEvents[1] {
            #expect(completed2 == 2)
            #expect(total2 == 3)
        }
        
        if case .converting(let completed3, let total3) = convertingEvents[2] {
            #expect(completed3 == 3)
            #expect(total3 == 3)
        }
    }
    
    @Test("ImageConversionService should emit completed event with output items")
    func testCompletedEvent() async throws {
        let service = createService()
        let items = [createInputItem()]
        
        let stream = try service.convert(items: items, imageFormat: .lossless(.png))
        
        var completedEvent: ImageConversionService.Event?
        for await event in stream {
            if case .completed = event {
                completedEvent = event
                break
            }
        }
        
        #expect(completedEvent != nil)
        
        if case .completed(let outputItems) = completedEvent {
            #expect(outputItems.count == 1)
            #expect(FileManager.default.fileExists(atPath: outputItems[0].url.path))
        } else {
            Issue.record("Expected completed event with output items")
        }
    }
    
    @Test("ImageConversionService should handle empty items list")
    func testEmptyItemsList() async throws {
        let service = createService()
        let items: [InputItem] = []
        
        let stream = try service.convert(items: items, imageFormat: .lossless(.png))
        
        var events: [ImageConversionService.Event] = []
        for await event in stream {
            events.append(event)
        }
        
        #expect(events.count == 2) // started and completed
        #expect(events.first == .started)
        
        if case .completed(let outputItems) = events.last {
            #expect(outputItems.isEmpty)
        } else {
            Issue.record("Expected completed event")
        }
    }
    
    @Test("ImageConversionService should use correct filename format")
    func testFilenameFormat() async throws {
        let service = createService()
        let items = [createInputItem()]
        
        let stream = try service.convert(items: items, imageFormat: .lossless(.png))
        
        var outputItems: [OutputItem] = []
        for await event in stream {
            if case .completed(let items) = event {
                outputItems = items
            }
        }
        
        #expect(!outputItems.isEmpty)
        let filename = outputItems[0].url.lastPathComponent
        #expect(filename.hasSuffix(".png"))
    }
    
    @Test("ImageConversionService should handle conversion failure gracefully")
    func testConversionFailure() async throws {
        // Create service that returns nil for conversion (simulating failure)
        let service = ImageConversionService(
            metadata: { _ in
                ImageMetadata(
                    filename: "test",
                    fileExtension: "jpg",
                    fileSize: 100,
                    dimensions: CGSize(width: 100, height: 100),
                    contentType: "public.jpeg"
                )
            },
            imageData: { _, _ in Data("test".utf8) },
            fileURLFor: { item in
                if case .fileURL(let url) = item.source {
                    return url
                }
                throw NSError(domain: "Test", code: 1)
            },
            prepareOutputDirectory: {},
            writeData: { data, filename in
                let tempDir = FileManager.default.temporaryDirectory
                let url = tempDir.appendingPathComponent(filename)
                try data.write(to: url)
                return url
            },
            convert: { _, _ in nil } // Return nil to simulate conversion failure
        )
        
        let items = [createInputItem()]
        let stream = try service.convert(items: items, imageFormat: .lossless(.png))
        
        var outputItems: [OutputItem] = []
        for await event in stream {
            if case .completed(let items) = event {
                outputItems = items
            }
        }
        
        // When conversion returns nil, item should be skipped
        #expect(outputItems.isEmpty)
    }
    
    @Test("ImageConversionService should prepare output directory")
    func testPrepareOutputDirectory() async throws {
        var prepareCalled = false
        let service = ImageConversionService(
            metadata: { _ in
                ImageMetadata(
                    filename: "test",
                    fileExtension: "jpg",
                    fileSize: 100,
                    dimensions: CGSize(width: 100, height: 100),
                    contentType: "public.jpeg"
                )
            },
            imageData: { _, _ in Data("test".utf8) },
            fileURLFor: { item in
                if case .fileURL(let url) = item.source {
                    return url
                }
                throw NSError(domain: "Test", code: 1)
            },
            prepareOutputDirectory: {
                prepareCalled = true
            },
            writeData: { data, filename in
                let tempDir = FileManager.default.temporaryDirectory
                let url = tempDir.appendingPathComponent(filename)
                try data.write(to: url)
                return url
            },
            convert: { data, _ in data } // Return same data
        )
        
        let items = [createInputItem()]
        _ = try service.convert(items: items, imageFormat: .lossless(.png))
        
        // Wait a bit for async operations
        try? await Task.sleep(nanoseconds: 10_000_000)
        
        #expect(prepareCalled)
    }
    
    @Test("ImageConversionService should skip items that fail to load and still complete")
    func testFailingItemIsSkipped() async throws {
        let failingItem = InputItem(source: .fileURLHandler { callback in
            callback(.failure(CocoaError(.fileReadNoSuchFile)))
        })
        let service = ImageConversionService(
            metadata: { url in
                ImageMetadata(
                    filename: url.deletingPathExtension().lastPathComponent,
                    fileExtension: url.pathExtension,
                    fileSize: 100,
                    dimensions: CGSize(width: 100, height: 100),
                    contentType: "public.jpeg"
                )
            },
            imageData: { _, _ in Data("test".utf8) },
            fileURLFor: { item in
                switch item.source {
                case let .fileURL(url):
                    return url
                case .fileURLHandler:
                    throw CocoaError(.fileReadNoSuchFile)
                }
            },
            prepareOutputDirectory: {},
            writeData: { data, filename in
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("output-\(UUID().uuidString)-\(filename)")
                try data.write(to: url)
                return url
            },
            convert: { data, _ in data }
        )

        let stream = try service.convert(items: [failingItem, createInputItem()], imageFormat: .lossless(.png))

        var events: [ImageConversionService.Event] = []
        for await event in stream {
            events.append(event)
        }

        #expect(events.contains(.converting(completed: 2, total: 2)))
        if case .completed(let outputItems) = events.last {
            #expect(outputItems.count == 1)
        } else {
            Issue.record("Expected completed event")
        }
    }

    @Test("ImageConversionService should give inputs with the same name distinct output filenames")
    func testDuplicateFilenames() async throws {
        let service = ImageConversionService(
            metadata: { _ in
                ImageMetadata(
                    filename: "IMG_0001",
                    fileExtension: "heic",
                    fileSize: 100,
                    dimensions: CGSize(width: 100, height: 100),
                    contentType: "public.heic"
                )
            },
            imageData: { _, _ in Data("test".utf8) },
            fileURLFor: { item in
                if case .fileURL(let url) = item.source {
                    return url
                }
                throw NSError(domain: "Test", code: 1)
            },
            prepareOutputDirectory: {},
            writeData: { _, filename in
                URL(fileURLWithPath: "/output").appendingPathComponent(filename)
            },
            convert: { data, _ in data }
        )

        let stream = try service.convert(
            items: [createInputItem(), createInputItem(), createInputItem()],
            imageFormat: .lossy(.jpeg)
        )

        var outputItems: [OutputItem] = []
        for await event in stream {
            if case .completed(let items) = event {
                outputItems = items
            }
        }

        #expect(outputItems.map(\.url.lastPathComponent) == ["IMG_0001.jpg", "IMG_0001 2.jpg", "IMG_0001 3.jpg"])
    }

    @Test("uniqueFilename should fall back to a default name for empty base names")
    func testUniqueFilenameEmptyBaseName() {
        var usedFilenames: Set<String> = []
        let filename = ImageConversionService.uniqueFilename(
            baseName: "",
            fileExtension: "png",
            usedFilenames: &usedFilenames
        )

        #expect(filename == "image.png")
    }

    @Test("ImageConversionService should stop converting when the consumer is cancelled")
    func testCancellation() async throws {
        let counter = Counter()
        let service = ImageConversionService(
            metadata: { url in
                ImageMetadata(
                    filename: url.deletingPathExtension().lastPathComponent,
                    fileExtension: url.pathExtension,
                    fileSize: 100,
                    dimensions: CGSize(width: 100, height: 100),
                    contentType: "public.jpeg"
                )
            },
            imageData: { _, _ in Data("test".utf8) },
            fileURLFor: { item in
                if case .fileURL(let url) = item.source {
                    return url
                }
                throw NSError(domain: "Test", code: 1)
            },
            prepareOutputDirectory: {},
            writeData: { _, filename in
                URL(fileURLWithPath: "/output").appendingPathComponent(filename)
            },
            convert: { data, _ in
                await counter.increment()
                try? await Task.sleep(for: .milliseconds(50))
                return data
            }
        )

        let items = (0..<20).map { _ in createInputItem() }
        let consumer = Task {
            for await event in try service.convert(items: items, imageFormat: .lossless(.png)) {
                if case .converting(completed: 1, total: _) = event {
                    withUnsafeCurrentTask { $0?.cancel() }
                }
            }
        }
        _ = await consumer.result
        try await Task.sleep(for: .milliseconds(300))

        #expect(await counter.value < items.count)
    }

    // MARK: - Helper Methods
    
    private func createService() -> ImageConversionService {
        let tempDir = FileManager.default.temporaryDirectory
        
        return ImageConversionService(
            metadata: { url in
                ImageMetadata(
                    filename: url.deletingPathExtension().lastPathComponent,
                    fileExtension: url.pathExtension,
                    fileSize: 100,
                    dimensions: CGSize(width: 100, height: 100),
                    contentType: "public.jpeg"
                )
            },
            imageData: { _, _ in
                // Create minimal valid image data
                Data("fake-image-data".utf8)
            },
            fileURLFor: { item in
                if case .fileURL(let url) = item.source {
                    return url
                }
                throw NSError(domain: "Test", code: 1)
            },
            prepareOutputDirectory: {
                // No-op for testing
            },
            writeData: { data, filename in
                let url = tempDir.appendingPathComponent("output-\(UUID().uuidString)-\(filename)")
                try data.write(to: url)
                return url
            },
            convert: { data, _ in
                // Return converted data (simplified for testing)
                data
            }
        )
    }
    
    private func createInputItem() -> InputItem {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-\(UUID().uuidString).jpg")
        
        // Create a temporary file
        try? Data("test".utf8).write(to: tempFile)
        
        return InputItem(source: .fileURL(tempFile))
    }
}

// MARK: - Event Equatable Extension

extension ImageConversionService.Event: @retroactive Equatable {
    public static func == (lhs: ImageConversionService.Event, rhs: ImageConversionService.Event) -> Bool {
        switch (lhs, rhs) {
        case (.started, .started):
            return true
        case (.converting(let lhsCompleted, let lhsTotal), .converting(let rhsCompleted, let rhsTotal)):
            return lhsCompleted == rhsCompleted && lhsTotal == rhsTotal
        case (.completed(let lhsItems), .completed(let rhsItems)):
            return lhsItems.count == rhsItems.count && lhsItems.map(\.id) == rhsItems.map(\.id)
        default:
            return false
        }
    }
}


private actor Counter {
    private(set) var value = 0

    func increment() {
        value += 1
    }
}
