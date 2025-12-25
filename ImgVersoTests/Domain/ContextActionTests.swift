import Foundation
import Testing
@testable import ImgVerso

struct ContextActionTests {
    
    @Test("ContextAction should initialize with all properties")
    func testContextActionInitialization() {
        var executed = false
        let action = ContextAction(
            title: "Test Action",
            systemImage: "test.icon",
            destructive: false,
            execute: { executed = true }
        )
        
        #expect(action.title == "Test Action")
        #expect(action.systemImage == "test.icon")
        #expect(action.destructive == false)
        #expect(!executed)
        
        action.execute()
        #expect(executed)
    }
    
    @Test("ContextAction should support destructive actions")
    func testContextActionDestructive() {
        let action = ContextAction(
            title: "Delete",
            systemImage: "trash",
            destructive: true,
            execute: {}
        )
        
        #expect(action.destructive == true)
    }
    
    @Test("ContextAction should have unique IDs")
    func testContextActionUniqueIDs() {
        let action1 = ContextAction(title: "Action 1", systemImage: "icon1", execute: {})
        let action2 = ContextAction(title: "Action 2", systemImage: "icon2", execute: {})
        
        #expect(action1.id != action2.id)
    }
}

