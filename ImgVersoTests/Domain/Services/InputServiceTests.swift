import Foundation
import Testing
@testable import ImgVerso

struct InputServiceTests {
    
    @Test("InputService should initialize with empty items")
    func testInitialState() {
        let service = InputService()
        #expect(service.items.isEmpty)
    }
    
    @Test("InputService should add items")
    func testAddItems() {
        let service = InputService()
        let url1 = URL(fileURLWithPath: "/test1.jpg")
        let url2 = URL(fileURLWithPath: "/test2.jpg")
        
        let item1 = InputItem(source: .fileURL(url1))
        let item2 = InputItem(source: .fileURL(url2))
        
        service.didAdd(items: [item1, item2])
        
        #expect(service.items.count == 2)
        #expect(service.items.contains(item1))
        #expect(service.items.contains(item2))
    }
    
    @Test("InputService should append items when adding multiple times")
    func testAddItemsMultipleTimes() {
        let service = InputService()
        let url1 = URL(fileURLWithPath: "/test1.jpg")
        let url2 = URL(fileURLWithPath: "/test2.jpg")
        let url3 = URL(fileURLWithPath: "/test3.jpg")
        
        let item1 = InputItem(source: .fileURL(url1))
        let item2 = InputItem(source: .fileURL(url2))
        let item3 = InputItem(source: .fileURL(url3))
        
        service.didAdd(items: [item1])
        #expect(service.items.count == 1)
        
        service.didAdd(items: [item2, item3])
        #expect(service.items.count == 3)
        #expect(service.items.contains(item1))
        #expect(service.items.contains(item2))
        #expect(service.items.contains(item3))
    }
    
    @Test("InputService should remove items")
    func testRemoveItems() {
        let service = InputService()
        let url1 = URL(fileURLWithPath: "/test1.jpg")
        let url2 = URL(fileURLWithPath: "/test2.jpg")
        let url3 = URL(fileURLWithPath: "/test3.jpg")
        
        let item1 = InputItem(source: .fileURL(url1))
        let item2 = InputItem(source: .fileURL(url2))
        let item3 = InputItem(source: .fileURL(url3))
        
        service.didAdd(items: [item1, item2, item3])
        #expect(service.items.count == 3)
        
        service.didRemove(items: [item2])
        #expect(service.items.count == 2)
        #expect(service.items.contains(item1))
        #expect(!service.items.contains(item2))
        #expect(service.items.contains(item3))
    }
    
    @Test("InputService should remove multiple items")
    func testRemoveMultipleItems() {
        let service = InputService()
        let url1 = URL(fileURLWithPath: "/test1.jpg")
        let url2 = URL(fileURLWithPath: "/test2.jpg")
        let url3 = URL(fileURLWithPath: "/test3.jpg")
        
        let item1 = InputItem(source: .fileURL(url1))
        let item2 = InputItem(source: .fileURL(url2))
        let item3 = InputItem(source: .fileURL(url3))
        
        service.didAdd(items: [item1, item2, item3])
        service.didRemove(items: [item1, item3])
        
        #expect(service.items.count == 1)
        #expect(service.items.contains(item2))
        #expect(!service.items.contains(item1))
        #expect(!service.items.contains(item3))
    }
    
    @Test("InputService should handle removing non-existent items")
    func testRemoveNonExistentItems() {
        let service = InputService()
        let url1 = URL(fileURLWithPath: "/test1.jpg")
        let url2 = URL(fileURLWithPath: "/test2.jpg")
        
        let item1 = InputItem(source: .fileURL(url1))
        let item2 = InputItem(source: .fileURL(url2))
        
        service.didAdd(items: [item1])
        service.didRemove(items: [item2]) // Remove item that doesn't exist
        
        #expect(service.items.count == 1)
        #expect(service.items.contains(item1))
    }
    
    @Test("InputService should remove all items")
    func testRemoveAll() {
        let service = InputService()
        let url1 = URL(fileURLWithPath: "/test1.jpg")
        let url2 = URL(fileURLWithPath: "/test2.jpg")
        
        let item1 = InputItem(source: .fileURL(url1))
        let item2 = InputItem(source: .fileURL(url2))
        
        service.didAdd(items: [item1, item2])
        #expect(service.items.count == 2)
        
        service.removeAll()
        #expect(service.items.isEmpty)
    }
    
    @Test("InputService should handle empty operations")
    func testEmptyOperations() {
        let service = InputService()
        
        service.didAdd(items: [])
        #expect(service.items.isEmpty)
        
        service.didRemove(items: [])
        #expect(service.items.isEmpty)
        
        service.removeAll()
        #expect(service.items.isEmpty)
    }
}

