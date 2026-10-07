import Foundation
import Testing
@testable import ImgZen

struct FileURLResolverTests {

    @Test("FileURLResolver should return file URLs unchanged")
    func testFileURLSource() async throws {
        let url = URL(fileURLWithPath: "/test/image.jpg")
        let resolver = FileURLResolver(cacheDirectory: makeCacheDirectory())

        let resolvedURL = try await resolver.fileURL(for: InputItem(source: .fileURL(url)))

        #expect(resolvedURL == url)
    }

    @Test("FileURLResolver should copy handler-provided files into the cache directory")
    func testHandlerSourceIsCopied() async throws {
        let cacheDirectory = makeCacheDirectory()
        let sourceURL = try makeSourceFile(named: "IMG_0001.HEIC")
        let resolver = FileURLResolver(cacheDirectory: cacheDirectory)

        let resolvedURL = try await resolver.fileURL(for: InputItem(source: .fileURLHandler { callback in
            callback(.success(sourceURL))
        }))

        #expect(resolvedURL.lastPathComponent == "IMG_0001.HEIC")
        #expect(resolvedURL.path.hasPrefix(cacheDirectory.path))
        #expect(FileManager.default.fileExists(atPath: resolvedURL.path))
    }

    @Test("FileURLResolver should keep files with the same name from different items apart")
    func testSameFilenameDifferentItems() async throws {
        let resolver = FileURLResolver(cacheDirectory: makeCacheDirectory())
        let firstSourceURL = try makeSourceFile(named: "IMG_0001.HEIC", contents: "first")
        let secondSourceURL = try makeSourceFile(named: "IMG_0001.HEIC", contents: "second")

        let firstURL = try await resolver.fileURL(for: InputItem(source: .fileURLHandler { $0(.success(firstSourceURL)) }))
        let secondURL = try await resolver.fileURL(for: InputItem(source: .fileURLHandler { $0(.success(secondSourceURL)) }))

        #expect(firstURL != secondURL)
        #expect(try String(contentsOf: firstURL, encoding: .utf8) == "first")
        #expect(try String(contentsOf: secondURL, encoding: .utf8) == "second")
    }

    @Test("FileURLResolver should load each item only once")
    func testHandlerIsCalledOnce() async throws {
        let sourceURL = try makeSourceFile(named: "image.png")
        let resolver = FileURLResolver(cacheDirectory: makeCacheDirectory())
        let calls = Calls()
        let item = InputItem(source: .fileURLHandler { callback in
            calls.increment()
            callback(.success(sourceURL))
        })

        async let first = resolver.fileURL(for: item)
        async let second = resolver.fileURL(for: item)
        let urls = try await [first, second]

        #expect(urls[0] == urls[1])
        #expect(calls.value == 1)
    }

    @Test("FileURLResolver should throw instead of hanging when the source fails")
    func testHandlerFailure() async throws {
        let resolver = FileURLResolver(cacheDirectory: makeCacheDirectory())
        let item = InputItem(source: .fileURLHandler { callback in
            callback(.failure(CocoaError(.fileReadNoSuchFile)))
        })

        await #expect(throws: CocoaError.self) {
            try await resolver.fileURL(for: item)
        }
    }

    // MARK: - Helper Methods

    private func makeCacheDirectory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "resolver-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    private func makeSourceFile(named name: String, contents: String = "test") throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try Data(contents.utf8).write(to: url)
        return url
    }
}

private final class Calls: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.withLock { count }
    }

    func increment() {
        lock.withLock { count += 1 }
    }
}
