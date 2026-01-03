import Foundation
import UniformTypeIdentifiers
import Testing
@testable import ImgZen

struct ImageFormatTests {
    
    // MARK: - LosslessImageFormat Tests
    
    @Test("LosslessImageFormat should have correct file extensions")
    func testLosslessImageFormatFileExtensions() {
        #expect(LosslessImageFormat.png.fileExtension == "png")
        #expect(LosslessImageFormat.tiff.fileExtension == "tiff")
        #expect(LosslessImageFormat.bmp.fileExtension == "bmp")
    }
    
    @Test("LosslessImageFormat should have correct UTType")
    func testLosslessImageFormatUTType() {
        #expect(LosslessImageFormat.png.utType == .png)
        #expect(LosslessImageFormat.tiff.utType == .tiff)
        #expect(LosslessImageFormat.bmp.utType == .bmp)
    }
    
    @Test("LosslessImageFormat should be identifiable")
    func testLosslessImageFormatIdentifiable() {
        #expect(LosslessImageFormat.png.id == "PNG")
        #expect(LosslessImageFormat.tiff.id == "TIFF")
        #expect(LosslessImageFormat.bmp.id == "BMP")
    }
    
    @Test("LosslessImageFormat should be CaseIterable")
    func testLosslessImageFormatCaseIterable() {
        let allCases = LosslessImageFormat.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.png))
        #expect(allCases.contains(.tiff))
        #expect(allCases.contains(.bmp))
    }
    
    // MARK: - LossyImageFormat Tests
    
    @Test("LossyImageFormat should have correct file extensions")
    func testLossyImageFormatFileExtensions() {
        #expect(LossyImageFormat.jpeg.fileExtension == "jpg")
        #expect(LossyImageFormat.heic.fileExtension == "heic")
        #expect(LossyImageFormat.webp.fileExtension == "webp")
    }
    
    @Test("LossyImageFormat should have correct UTType")
    func testLossyImageFormatUTType() {
        #expect(LossyImageFormat.jpeg.utType == .jpeg)
        #expect(LossyImageFormat.heic.utType == .heic)
        #expect(LossyImageFormat.webp.utType?.identifier == "public.webp" || LossyImageFormat.webp.utType?.identifier.contains("webp") == true)
    }
    
    @Test("LossyImageFormat should be identifiable")
    func testLossyImageFormatIdentifiable() {
        #expect(LossyImageFormat.jpeg.id == "JPEG")
        #expect(LossyImageFormat.heic.id == "HEIC")
        #expect(LossyImageFormat.webp.id == "WebP")
    }
    
    @Test("LossyImageFormat should be CaseIterable")
    func testLossyImageFormatCaseIterable() {
        let allCases = LossyImageFormat.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.jpeg))
        #expect(allCases.contains(.heic))
        #expect(allCases.contains(.webp))
    }
    
    // MARK: - ImageFormat Tests
    
    @Test("ImageFormat lossless should return correct file extension")
    func testImageFormatLosslessFileExtension() {
        let format = ImageFormat.lossless(.png)
        #expect(format.fileExtension == "png")
        
        let format2 = ImageFormat.lossless(.tiff)
        #expect(format2.fileExtension == "tiff")
    }
    
    @Test("ImageFormat lossy should return correct file extension")
    func testImageFormatLossyFileExtension() {
        let format = ImageFormat.lossy(.jpeg)
        #expect(format.fileExtension == "jpg")
        
        let format2 = ImageFormat.lossy(.heic)
        #expect(format2.fileExtension == "heic")
        
        let format3 = ImageFormat.lossy(.webp)
        #expect(format3.fileExtension == "webp")
    }
    
    @Test("ImageFormat should return correct UTType")
    func testImageFormatUTType() {
        let losslessFormat = ImageFormat.lossless(.png)
        #expect(losslessFormat.utType == .png)
        
        let lossyFormat = ImageFormat.lossy(.jpeg)
        #expect(lossyFormat.utType == .jpeg)
    }
    
    @Test("ImageFormat isLossy should return correct value")
    func testImageFormatIsLossy() {
        let losslessFormat = ImageFormat.lossless(.png)
        #expect(losslessFormat.isLossy == false)
        
        let lossyFormat = ImageFormat.lossy(.jpeg)
        #expect(lossyFormat.isLossy == true)
    }
    
    @Test("ImageFormat losslessFormat should return format for lossless")
    func testImageFormatLosslessFormat() {
        let losslessFormat = ImageFormat.lossless(.png)
        #expect(losslessFormat.losslessFormat == .png)
        #expect(losslessFormat.lossyFormat == nil)
        
        let lossyFormat = ImageFormat.lossy(.jpeg)
        #expect(lossyFormat.losslessFormat == nil)
    }
    
    @Test("ImageFormat lossyFormat should return format for lossy")
    func testImageFormatLossyFormat() {
        let lossyFormat = ImageFormat.lossy(.jpeg)
        #expect(lossyFormat.lossyFormat == .jpeg)
        #expect(lossyFormat.losslessFormat == nil)
        
        let losslessFormat = ImageFormat.lossless(.png)
        #expect(losslessFormat.lossyFormat == nil)
    }
    
    @Test("ImageFormat should be identifiable")
    func testImageFormatIdentifiable() {
        let losslessFormat = ImageFormat.lossless(.png)
        #expect(losslessFormat.id == "PNG")
        
        let lossyFormat = ImageFormat.lossy(.jpeg)
        #expect(lossyFormat.id == "JPEG")
    }
    
    @Test("ImageFormat should be CaseIterable")
    func testImageFormatCaseIterable() {
        let allCases = ImageFormat.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.lossless(.png)))
        #expect(allCases.contains(.lossless(.bmp)))
        #expect(allCases.contains(.lossless(.tiff)))
    }
    
    @Test("ImageFormat should be equatable")
    func testImageFormatEquatable() {
        let format1 = ImageFormat.lossless(.png)
        let format2 = ImageFormat.lossless(.png)
        let format3 = ImageFormat.lossless(.tiff)
        
        #expect(format1 == format2)
        #expect(format1 != format3)
        
        let lossy1 = ImageFormat.lossy(.jpeg, compressionQuality: 0.8)
        let lossy2 = ImageFormat.lossy(.jpeg, compressionQuality: 0.8)
        let lossy3 = ImageFormat.lossy(.jpeg, compressionQuality: 0.9)
        
        #expect(lossy1 == lossy2)
        #expect(lossy1 != lossy3)
        
        #expect(format1 != lossy1)
    }
    
    @Test("ImageFormat lossy should store compression quality")
    func testImageFormatCompressionQuality() {
        let format1 = ImageFormat.lossy(.jpeg, compressionQuality: 0.5)
        let format2 = ImageFormat.lossy(.jpeg, compressionQuality: 0.8)
        
        #expect(format1 != format2)
        
        if case .lossy(_, let quality1) = format1 {
            #expect(quality1 == 0.5)
        } else {
            Issue.record("Expected lossy format")
        }
        
        if case .lossy(_, let quality2) = format2 {
            #expect(quality2 == 0.8)
        } else {
            Issue.record("Expected lossy format")
        }
    }
    
    @Test("ImageFormat lossy should default compression quality to 1.0")
    func testImageFormatDefaultCompressionQuality() {
        let format = ImageFormat.lossy(.jpeg)
        
        if case .lossy(_, let quality) = format {
            #expect(quality == 1.0)
        } else {
            Issue.record("Expected lossy format")
        }
    }
}

