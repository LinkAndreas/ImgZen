import Foundation
import UIKit
import Testing
@testable import ImgVerso

struct ImageConverterTests {
    
    @Test("ImgVerso.convertImageData should route WebP to WebP converter")
    func testWebPRouting() async {
        // Create a minimal valid PNG image (1x1 pixel)
        guard let testImageData = createMinimalImageData() else {
            Issue.record("Failed to create test image data")
            return
        }
        
        // Test that WebP format routes correctly (may return nil if WebP encoding fails, but should not crash)
        let result = await ImgVerso.convertImageData(testImageData, to: .lossy(.webp, compressionQuality: 0.8))
        
        // Result can be nil if conversion fails, but function should complete without error
        // We're mainly testing the routing logic works
        #expect(result != nil)
    }
    
    @Test("ImgVerso.convertImageData should route non-WebP formats to ImageIO converter")
    func testImageIORouting() async {
        guard let testImageData = createMinimalImageData() else {
            Issue.record("Failed to create test image data")
            return
        }
        
        // Test PNG conversion (should use ImageIO)
        let pngResult = await ImgVerso.convertImageData(testImageData, to: .lossless(.png))
        // Result may be nil, but should not crash
        
        // Test JPEG conversion (should use ImageIO)
        let jpegResult = await ImgVerso.convertImageData(testImageData, to: .lossy(.jpeg, compressionQuality: 0.8))

        // Result may be nil, but should not crash
        #expect(pngResult != nil)
        #expect(jpegResult != nil)
    }
    
    @Test("ImgVerso.convertImageData should return nil for invalid image data")
    func testInvalidImageData() async {
        let invalidData = Data("not an image".utf8)
        
        let result = await ImgVerso.convertImageData(invalidData, to: .lossless(.png))
        
        // Should return nil for invalid data
        #expect(result == nil)
    }
    
    @Test("ImgVerso.convertImageData should handle empty data")
    func testEmptyData() async {
        let emptyData = Data()
        
        let result = await ImgVerso.convertImageData(emptyData, to: .lossless(.png))
        
        // Should return nil for empty data
        #expect(result == nil)
    }
    
    @Test("ImgVerso.convertImageData should handle different compression qualities for WebP")
    func testWebPCompressionQuality() async {
        guard let testImageData = createMinimalImageData() else {
            Issue.record("Failed to create test image data")
            return
        }
        
        // Test with different compression qualities
        let result1 = await ImgVerso.convertImageData(testImageData, to: .lossy(.webp, compressionQuality: 0.5))
        let result2 = await ImgVerso.convertImageData(testImageData, to: .lossy(.webp, compressionQuality: 1.0))
        
        // Both should complete (results may be nil if conversion fails)
        // Lower quality might produce smaller files, but we can't easily test that without actual conversion
        #expect(result1 != nil)
        #expect(result2 != nil)
    }
    
    @Test("ImgVerso.convertImageData should handle different compression qualities for JPEG")
    func testJPEGCompressionQuality() async {
        guard let testImageData = createMinimalImageData() else {
            Issue.record("Failed to create test image data")
            return
        }
        
        // Test with different compression qualities
        let result1 = await ImgVerso.convertImageData(testImageData, to: .lossy(.jpeg, compressionQuality: 0.5))
        let result2 = await ImgVerso.convertImageData(testImageData, to: .lossy(.jpeg, compressionQuality: 1.0))
        
        // Both should complete (results may be nil if conversion fails)
        #expect(result1 != nil)
        #expect(result2 != nil)
    }
    
    @Test("ImgVerso.convertImageData should handle all lossless formats")
    func testLosslessFormats() async {
        guard let testImageData = createMinimalImageData() else {
            Issue.record("Failed to create test image data")
            return
        }
        
        let formats: [LosslessImageFormat] = [.png, .tiff, .bmp]
        
        for format in formats {
            let result = await ImgVerso.convertImageData(testImageData, to: .lossless(format))
            #expect(result != nil)
        }
    }
    
    @Test("ImgVerso.convertImageData should handle all lossy formats")
    func testLossyFormats() async {
        guard let testImageData = createMinimalImageData() else {
            Issue.record("Failed to create test image data")
            return
        }
        
        let formats: [LossyImageFormat] = [.jpeg, .heic, .webp]
        
        for format in formats {
            let result = await ImgVerso.convertImageData(testImageData, to: .lossy(format, compressionQuality: 0.8))
            #expect(result != nil)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Creates a minimal valid PNG image data (1x1 pixel, transparent)
    private func createMinimalImageData() -> Data? {
        // Create a 1x1 pixel PNG image
        let size = CGSize(width: 1, height: 1)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        return image.pngData()
    }
}

