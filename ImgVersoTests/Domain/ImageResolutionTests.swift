import Foundation
import Testing
@testable import ImgVerso

struct ImageResolutionTests {
    
    @Test("ImageResolution should have full and thumbnail cases")
    func testImageResolutionCases() {
        let full = ImageResolution.full
        let thumbnail = ImageResolution.thumbnail
        
        // Verify both cases exist and are distinct
        #expect(full != thumbnail)
    }
}

