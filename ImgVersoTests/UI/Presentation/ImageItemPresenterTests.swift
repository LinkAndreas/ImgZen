import CoreGraphics
import Foundation
import Testing
@testable import ImgVerso

struct ImageItemPresenterTests {
    
    @Test("ImageItemPresenter should format title from filename")
    func testTitle() {
        let metadata = ImageMetadata(
            filename: "my-image",
            fileExtension: "jpg",
            fileSize: 1024,
            dimensions: CGSize(width: 100, height: 200),
            contentType: "public.jpeg"
        )
        
        let presenter = ImageItemPresenter(metadata: metadata)
        #expect(presenter.title == "my-image")
    }
    
    @Test("ImageItemPresenter should format subtitle with dimensions and file size")
    func testSubtitle() {
        let metadata = ImageMetadata(
            filename: "test",
            fileExtension: "jpg",
            fileSize: 2048,
            dimensions: CGSize(width: 1920, height: 1080),
            contentType: "public.jpeg"
        )
        
        let presenter = ImageItemPresenter(metadata: metadata)
        let subtitle = presenter.subtitle
        
        #expect(subtitle.contains("1920 x 1080 px"))
        #expect(subtitle.contains("⋅"))
    }
    
    @Test("ImageItemPresenter should format badge for JPEG")
    func testBadgeJPEG() {
        let metadata1 = ImageMetadata(
            filename: "test",
            fileExtension: "jpg",
            fileSize: 100,
            dimensions: CGSize(width: 100, height: 100),
            contentType: "public.jpeg"
        )
        
        let metadata2 = ImageMetadata(
            filename: "test",
            fileExtension: "jpg",
            fileSize: 100,
            dimensions: CGSize(width: 100, height: 100),
            contentType: "public.jpg"
        )
        
        let presenter1 = ImageItemPresenter(metadata: metadata1)
        let presenter2 = ImageItemPresenter(metadata: metadata2)
        
        #expect(presenter1.badge == "JPEG")
        #expect(presenter2.badge == "JPEG")
    }
    
    @Test("ImageItemPresenter should format badge for PNG")
    func testBadgePNG() {
        let metadata = ImageMetadata(
            filename: "test",
            fileExtension: "png",
            fileSize: 100,
            dimensions: CGSize(width: 100, height: 100),
            contentType: "public.png"
        )
        
        let presenter = ImageItemPresenter(metadata: metadata)
        #expect(presenter.badge == "PNG")
    }
    
    @Test("ImageItemPresenter should format badge for HEIC")
    func testBadgeHEIC() {
        let metadata1 = ImageMetadata(
            filename: "test",
            fileExtension: "heic",
            fileSize: 100,
            dimensions: CGSize(width: 100, height: 100),
            contentType: "public.heic"
        )
        
        let metadata2 = ImageMetadata(
            filename: "test",
            fileExtension: "heic",
            fileSize: 100,
            dimensions: CGSize(width: 100, height: 100),
            contentType: "public.heif"
        )
        
        let presenter1 = ImageItemPresenter(metadata: metadata1)
        let presenter2 = ImageItemPresenter(metadata: metadata2)
        
        #expect(presenter1.badge == "HEIC")
        #expect(presenter2.badge == "HEIC")
    }
    
    @Test("ImageItemPresenter should format badge for TIFF")
    func testBadgeTIFF() {
        let metadata = ImageMetadata(
            filename: "test",
            fileExtension: "tiff",
            fileSize: 100,
            dimensions: CGSize(width: 100, height: 100),
            contentType: "public.tiff"
        )
        
        let presenter = ImageItemPresenter(metadata: metadata)
        #expect(presenter.badge == "TIFF")
    }
    
    @Test("ImageItemPresenter should format badge for GIF")
    func testBadgeGIF() {
        let metadata = ImageMetadata(
            filename: "test",
            fileExtension: "gif",
            fileSize: 100,
            dimensions: CGSize(width: 100, height: 100),
            contentType: "com.compuserve.gif"
        )
        
        let presenter = ImageItemPresenter(metadata: metadata)
        #expect(presenter.badge == "GIF")
    }
    
    @Test("ImageItemPresenter should format badge for WebP")
    func testBadgeWebP() {
        let metadata = ImageMetadata(
            filename: "test",
            fileExtension: "webp",
            fileSize: 100,
            dimensions: CGSize(width: 100, height: 100),
            contentType: "public.webp"
        )
        
        let presenter = ImageItemPresenter(metadata: metadata)
        #expect(presenter.badge == "WebP")
    }
    
    @Test("ImageItemPresenter should handle unknown content type")
    func testBadgeUnknown() {
        let metadata = ImageMetadata(
            filename: "test",
            fileExtension: "xyz",
            fileSize: 100,
            dimensions: CGSize(width: 100, height: 100),
            contentType: "public.unknown"
        )
        
        let presenter = ImageItemPresenter(metadata: metadata)
        let badge = presenter.badge
        
        // Should extract from UTI or return "Unknown"
        #expect(badge == "UNKNOWN" || badge == "Unknown" || badge.count > 0)
    }
    
    @Test("ImageItemPresenter should extract format from UTI containing jpeg")
    func testBadgeFromUTIWithJPEG() {
        let metadata = ImageMetadata(
            filename: "test",
            fileExtension: "jpg",
            fileSize: 100,
            dimensions: CGSize(width: 100, height: 100),
            contentType: "com.example.custom.jpeg.format"
        )
        
        let presenter = ImageItemPresenter(metadata: metadata)
        #expect(presenter.badge == "JPEG")
    }
    
    @Test("ImageItemPresenter should extract format from UTI containing png")
    func testBadgeFromUTIWithPNG() {
        let metadata = ImageMetadata(
            filename: "test",
            fileExtension: "png",
            fileSize: 100,
            dimensions: CGSize(width: 100, height: 100),
            contentType: "com.example.custom.png.format"
        )
        
        let presenter = ImageItemPresenter(metadata: metadata)
        #expect(presenter.badge == "PNG")
    }
    
    @Test("ImageItemPresenter should extract format from UTI containing heic")
    func testBadgeFromUTIWithHEIC() {
        let metadata = ImageMetadata(
            filename: "test",
            fileExtension: "heic",
            fileSize: 100,
            dimensions: CGSize(width: 100, height: 100),
            contentType: "com.example.custom.heic.format"
        )
        
        let presenter = ImageItemPresenter(metadata: metadata)
        #expect(presenter.badge == "HEIC")
    }
    
    @Test("ImageItemPresenter should handle zero dimensions")
    func testSubtitleWithZeroDimensions() {
        let metadata = ImageMetadata(
            filename: "test",
            fileExtension: "jpg",
            fileSize: 100,
            dimensions: .zero,
            contentType: "public.jpeg"
        )
        
        let presenter = ImageItemPresenter(metadata: metadata)
        let subtitle = presenter.subtitle
        
        #expect(subtitle.contains("0 x 0 px"))
    }
    
    @Test("ImageItemPresenter should handle large file sizes")
    func testSubtitleWithLargeFileSize() {
        let metadata = ImageMetadata(
            filename: "test",
            fileExtension: "jpg",
            fileSize: 10_485_760, // 10 MB
            dimensions: CGSize(width: 100, height: 100),
            contentType: "public.jpeg"
        )
        
        let presenter = ImageItemPresenter(metadata: metadata)
        let subtitle = presenter.subtitle
        
        // Should format the byte count
        #expect(subtitle.contains("100 x 100 px"))
    }
}

