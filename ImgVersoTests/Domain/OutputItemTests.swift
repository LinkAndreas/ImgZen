import Foundation
import Testing
@testable import ImgVerso

struct OutputItemTests {
    
    @Test("OutputItem should initialize with URL")
    func testOutputItemInitialization() {
        let url = URL(fileURLWithPath: "/output/test.jpg")
        let item = OutputItem(url: url)
        
        #expect(item.url == url)
    }
    
    @Test("OutputItem should allow custom ID")
    func testOutputItemCustomID() {
        let url = URL(fileURLWithPath: "/output/test.jpg")
        let customID = UUID()
        let item = OutputItem(id: customID, url: url)
        
        #expect(item.id == customID)
        #expect(item.url == url)
    }
    
    @Test("OutputItem should generate unique IDs by default")
    func testOutputItemUniqueIDs() {
        let url = URL(fileURLWithPath: "/output/test.jpg")
        let item1 = OutputItem(url: url)
        let item2 = OutputItem(url: url)
        
        #expect(item1.id != item2.id)
    }
    
    @Test("OutputItem should be equatable")
    func testOutputItemEquality() {
        let url1 = URL(fileURLWithPath: "/output/test1.jpg")
        let url2 = URL(fileURLWithPath: "/output/test2.jpg")
        let id = UUID()
        
        let item1 = OutputItem(id: id, url: url1)
        let item2 = OutputItem(id: id, url: url1)
        let item3 = OutputItem(id: id, url: url2)
        
        #expect(item1 == item2)
        #expect(item1 != item3)
    }
    
    @Test("OutputItem should be hashable")
    func testOutputItemHashable() {
        let url = URL(fileURLWithPath: "/output/test.jpg")
        let item = OutputItem(url: url)
        
        var hasher = Hasher()
        item.hash(into: &hasher)
        let hash = hasher.finalize()
        
        #expect(hash != 0)
    }
}

