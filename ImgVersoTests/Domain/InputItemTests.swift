import Foundation
import Testing
@testable import ImgVerso

struct InputItemTests {
    
    @Test("InputItem with fileURL source should store URL correctly")
    func testInputItemFileURLSource() {
        let url = URL(fileURLWithPath: "/test/image.jpg")
        let item = InputItem(source: .fileURL(url))
        
        if case .fileURL(let storedURL) = item.source {
            #expect(storedURL == url)
        } else {
            Issue.record("Expected fileURL source")
        }
    }
    
    @Test("InputItem with fileURLHandler source should store handler")
    func testInputItemFileURLHandlerSource() {
        let expectedURL = URL(fileURLWithPath: "/test/image.jpg")
        var handlerCalled = false
        
        let item = InputItem(source: .fileURLHandler { callback in
            handlerCalled = true
            callback(expectedURL)
        })
        
        if case .fileURLHandler(let handler) = item.source {
            handler { url in
                #expect(url == expectedURL)
            }
            #expect(handlerCalled)
        } else {
            Issue.record("Expected fileURLHandler source")
        }
    }
    
    @Test("InputItem should have unique IDs")
    func testInputItemUniqueIDs() {
        let url1 = URL(fileURLWithPath: "/test1.jpg")
        let url2 = URL(fileURLWithPath: "/test2.jpg")
        
        let item1 = InputItem(source: .fileURL(url1))
        let item2 = InputItem(source: .fileURL(url2))
        
        #expect(item1.id != item2.id)
    }
    
    @Test("InputItem equality should be based on ID")
    func testInputItemEquality() {
        let url = URL(fileURLWithPath: "/test.jpg")
        let item1 = InputItem(source: .fileURL(url))
        let item2 = InputItem(source: .fileURL(url))
        
        // Different IDs, so not equal
        #expect(item1 != item2)
        
        // Same item should be equal to itself
        #expect(item1 == item1)
    }
    
    @Test("InputItem should be hashable")
    func testInputItemHashable() {
        let url = URL(fileURLWithPath: "/test.jpg")
        let item = InputItem(source: .fileURL(url))
        
        var hasher1 = Hasher()
        var hasher2 = Hasher()
        
        item.hash(into: &hasher1)
        item.hash(into: &hasher2)
        
        #expect(hasher1.finalize() == hasher2.finalize())
    }
}

