import Foundation
import Testing
@testable import ImgZen

struct ImageMetadataTests {
    
    @Test("ImageMetadata should initialize with all properties")
    func testImageMetadataInitialization() {
        let metadata = ImageMetadata(
            filename: "test",
            fileExtension: "jpg",
            fileSize: 1024,
            dimensions: CGSize(width: 100, height: 200),
            contentType: "public.jpeg"
        )
        
        #expect(metadata.filename == "test")
        #expect(metadata.fileExtension == "jpg")
        #expect(metadata.fileSize == 1024)
        #expect(metadata.dimensions.width == 100)
        #expect(metadata.dimensions.height == 200)
        #expect(metadata.contentType == "public.jpeg")
    }
}
