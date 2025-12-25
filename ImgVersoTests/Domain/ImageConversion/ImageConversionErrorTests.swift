import Foundation
import Testing
@testable import ImgVerso

struct ImageConversionErrorTests {
    
    @Test("ImageConversionError should have all expected cases")
    func testErrorCases() {
        let error1 = ImageConversionError.invalidInputData
        let error2 = ImageConversionError.conversionFailed
        let error3 = ImageConversionError.unsupportedFormat
        
        // Verify all cases exist and are distinct
        #expect(error1 != error2)
        #expect(error2 != error3)
        #expect(error1 != error3)
    }
    
    @Test("ImageConversionError should conform to Error protocol")
    func testErrorConformance() {
        let error = ImageConversionError.invalidInputData
        
        // Can be used as Error
        func throwError() throws {
            throw error
        }
        
        do {
            try throwError()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is ImageConversionError)
        }
    }
    
    @Test("ImageConversionError should conform to Sendable")
    func testSendableConformance() {
        // Sendable conformance is compile-time checked
        // This test verifies the error can be used in concurrent contexts
        let error: any Error & Sendable = ImageConversionError.conversionFailed
        #expect(error is ImageConversionError)
    }
}

