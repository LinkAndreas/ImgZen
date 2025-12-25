import CoreGraphics
import Foundation
import Testing
@testable import ImgVerso

struct ImageServiceTests {
    
    @Test("ImageService should retrieve image data using repository")
    func testImageData() async throws {
        let expectedData = Data("test-image-data".utf8)
        let testURL = URL(fileURLWithPath: "/test/image.jpg")
        
        let mockRepository = MockImageRepository()
        mockRepository.imageData = expectedData
        
        let service = ImageService(imageRepository: mockRepository)
        
        let result = try await service.imageData(for: testURL, resolution: .full)
        
        #expect(result == expectedData)
        #expect(mockRepository.imageCalled)
        #expect(mockRepository.lastImageURL == testURL)
        #expect(mockRepository.lastImageResolution == .full)
    }
    
    @Test("ImageService should retrieve metadata using repository")
    func testMetadata() throws {
        let testURL = URL(fileURLWithPath: "/test/image.jpg")
        let expectedMetadata = ImageMetadata(
            filename: "test",
            fileExtension: "jpg",
            fileSize: 1024,
            dimensions: CGSize(width: 100, height: 200),
            contentType: "public.jpeg"
        )
        
        let mockRepository = MockImageRepository()
        mockRepository.metadataValue = expectedMetadata
        
        let service = ImageService(imageRepository: mockRepository)
        
        let result = try service.metadata(for: testURL)
        
        #expect(result.filename == expectedMetadata.filename)
        #expect(result.fileExtension == expectedMetadata.fileExtension)
        #expect(result.fileSize == expectedMetadata.fileSize)
        #expect(result.dimensions == expectedMetadata.dimensions)
        #expect(result.contentType == expectedMetadata.contentType)
        
        #expect(mockRepository.metadataCalled)
        #expect(mockRepository.lastMetadataURL == testURL)
    }
    
    @Test("ImageService should propagate errors from repository")
    func testPropagateErrors() async {
        let testURL = URL(fileURLWithPath: "/test/image.jpg")
        let testError = ImageRepositoryError.itemNotFound(atURL: testURL)
        
        let mockRepository = MockImageRepository()
        mockRepository.imageError = testError
        
        let service = ImageService(imageRepository: mockRepository)
        
        do {
            _ = try await service.imageData(for: testURL, resolution: .full)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is ImageRepositoryError)
        }
    }
    
    @Test("ImageService should handle different resolutions")
    func testDifferentResolutions() async throws {
        let fullData = Data("full-resolution".utf8)
        let thumbnailData = Data("thumbnail".utf8)
        let testURL = URL(fileURLWithPath: "/test/image.jpg")
        
        let mockRepository = MockImageRepository()
        
        // First call with full resolution
        mockRepository.imageData = fullData
        let service = ImageService(imageRepository: mockRepository)
        
        let fullResult = try await service.imageData(for: testURL, resolution: .full)
        #expect(fullResult == fullData)
        #expect(mockRepository.lastImageResolution == .full)
        
        // Second call with thumbnail resolution
        mockRepository.imageData = thumbnailData
        let thumbnailResult = try await service.imageData(for: testURL, resolution: .thumbnail)
        #expect(thumbnailResult == thumbnailData)
        #expect(mockRepository.lastImageResolution == .thumbnail)
    }
}

// MARK: - Mock ImageRepository

private class MockImageRepository: ImageRepository {
    var imageData: Data?
    var imageError: Error?
    var imageCalled = false
    var lastImageURL: URL?
    var lastImageResolution: ImageResolution?
    
    var metadataValue: ImageMetadata?
    var metadataError: Error?
    var metadataCalled = false
    var lastMetadataURL: URL?
    
    func image(for url: URL, resolution: ImageResolution) async throws -> ImageData {
        imageCalled = true
        lastImageURL = url
        lastImageResolution = resolution
        
        if let error = imageError {
            throw error
        }
        
        return imageData ?? Data()
    }
    
    func metadata(for url: URL) throws -> ImageMetadata {
        metadataCalled = true
        lastMetadataURL = url
        
        if let error = metadataError {
            throw error
        }
        
        return metadataValue ?? ImageMetadata(
            filename: "test",
            fileExtension: "jpg",
            fileSize: 0,
            dimensions: .zero,
            contentType: "public.image"
        )
    }
}

