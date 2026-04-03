import Foundation
import Testing
@testable import ImgZen

struct AsyncResourceLoaderTests {
    
    // MARK: - Initial State Tests
    
    @Test("Initial state should be notRequested")
    func testInitialState() {
        let loader = AsyncResourceLoader<String> {
            return "test"
        }
        
        #expect(loader.state == .notRequested)
    }
    
    // MARK: - Successful Loading Tests
    
    @Test("Successful load should transition through states correctly")
    func testSuccessfulLoad() async {
        let expectedResource = "test resource"
        let loader = AsyncResourceLoader<String> {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
            return expectedResource
        }
        
        // Initial state
        #expect(loader.state == .notRequested)
        
        // Start loading
        let loadTask = Task {
            await loader.load()
        }
        
        // Wait a bit to ensure state transitions to loading
        try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
        
        // Should be loading (might be success if very fast)
        let stateDuringLoad = loader.state
        #expect(stateDuringLoad == .loading || stateDuringLoad == .success(expectedResource))
        
        // Wait for completion
        await loadTask.value
        
        // Verify the resource value
        if case let .success(resource) = loader.state {
            #expect(resource == expectedResource)
        } else {
            Issue.record("Expected success state but got \(loader.state)")
        }
    }
    
    @Test("Successful load with integer resource")
    func testSuccessfulLoadWithInteger() async {
        let expectedValue = 42
        let loader = AsyncResourceLoader<Int> {
            return expectedValue
        }
        
        await loader.load()

        if case let .success(value) = loader.state {
            #expect(value == expectedValue)
        } else {
            Issue.record("Expected success state with value \(expectedValue)")
        }
    }
    
    @Test("Successful load with custom struct")
    func testSuccessfulLoadWithCustomType() async {
        struct TestResource {
            let id: Int
            let name: String
        }
        
        let expectedResource = TestResource(id: 1, name: "Test")
        let loader = AsyncResourceLoader<TestResource> {
            return expectedResource
        }
        
        await loader.load()
        
        if case let .success(resource) = loader.state {
            #expect(resource.id == expectedResource.id)
            #expect(resource.name == expectedResource.name)
        } else {
            Issue.record("Expected success state")
        }
    }
    
    // MARK: - Failure Tests
    
    @Test("Failed load should transition to failure state")
    func testFailedLoad() async {
        struct TestError: Error {
            let message: String
        }
        
        let expectedError = TestError(message: "Test error")
        let loader = AsyncResourceLoader<String> {
            throw expectedError
        }
        
        // Initial state
        #expect(loader.state == .notRequested)
        
        await loader.load()
        
        // Should be in failure state
        if case let .failure(error) = loader.state {
            #expect(error is TestError)
            if let testError = error as? TestError {
                #expect(testError.message == expectedError.message)
            }
        } else {
            Issue.record("Expected failure state but got \(loader.state)")
        }
    }
    
    @Test("Failed load with NSError")
    func testFailedLoadWithNSError() async {
        let expectedError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let loader = AsyncResourceLoader<String> {
            throw expectedError
        }
        
        await loader.load()
        
        if case let .failure(error) = loader.state {
            #expect((error as NSError).code == expectedError.code)
            #expect((error as NSError).domain == expectedError.domain)
        } else {
            Issue.record("Expected failure state")
        }
    }
    
    // MARK: - Multiple Load Tests
    
    @Test("Multiple load calls should work correctly")
    func testMultipleLoadCalls() async {
        var loadCount = 0
        let loader = AsyncResourceLoader<Int> {
            loadCount += 1
            return loadCount
        }
        
        // First load
        await loader.load()
        #expect(loadCount == 1)
        if case let .success(value) = loader.state {
            #expect(value == 1)
        }
        
        // Second load
        await loader.load()
        #expect(loadCount == 2)
        if case let .success(value) = loader.state {
            #expect(value == 2)
        }
        
        // Third load
        await loader.load()
        #expect(loadCount == 3)
        if case let .success(value) = loader.state {
            #expect(value == 3)
        }
    }
    
    @Test("Load after failure should retry")
    func testLoadAfterFailure() async {
        var shouldFail = true
        let loader = AsyncResourceLoader<String> {
            if shouldFail {
                shouldFail = false
                throw NSError(domain: "Test", code: 1)
            }
            return "success"
        }
        
        // First load - should fail
        await loader.load()
        #expect(loader.state.isFailure)
        
        // Second load - should succeed
        await loader.load()
        if case let .success(value) = loader.state {
            #expect(value == "success")
        } else {
            Issue.record("Expected success after retry")
        }
    }
    
    // MARK: - State Transitions Tests
    
    @Test("State should transition from notRequested to loading to success")
    func testStateTransitionsSuccess() async {
        let loader = AsyncResourceLoader<String> {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
            return "done"
        }
        
        #expect(loader.state == .notRequested)
        
        let loadTask = Task {
            await loader.load()
        }
        
        // Wait a bit to catch loading state
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Should be loading
        #expect(loader.state == .loading)
        
        // Wait for completion
        await loadTask.value
        
        // Should be success
        #expect(loader.state == .success("done"))
    }
    
    @Test("State should transition from notRequested to loading to failure")
    func testStateTransitionsFailure() async {
        let loader = AsyncResourceLoader<String> {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
            throw NSError(domain: "Test", code: 1)
        }
        
        #expect(loader.state == .notRequested)
        
        let loadTask = Task {
            await loader.load()
        }
        
        // Wait a bit to catch loading state
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Should be loading
        #expect(loader.state == .loading)
        
        // Wait for completion
        await loadTask.value
        
        // Should be failure
        #expect(loader.state.isFailure)
    }
    
    // MARK: - Edge Cases
    
    @Test("Load with immediate return should work")
    func testImmediateLoad() async {
        let loader = AsyncResourceLoader<String> {
            return "immediate"
        }
        
        await loader.load()
        
        if case let .success(value) = loader.state {
            #expect(value == "immediate")
        } else {
            Issue.record("Expected immediate success")
        }
    }
    
    @Test("Load with long delay should maintain loading state")
    func testLongDelayLoad() async {
        let loader = AsyncResourceLoader<String> {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
            return "delayed"
        }
        
        let loadTask = Task {
            await loader.load()
        }
        
        // Check multiple times during loading
        for _ in 0..<5 {
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            let currentState = loader.state
            #expect(currentState == .loading || currentState == .success("delayed"))
        }
        
        await loadTask.value
        #expect(loader.state == .success("delayed"))
    }
}

// MARK: - Helper Extensions

extension AsyncResourceLoader.State: @retroactive Equatable where Resource: Equatable {
    public static func == (lhs: AsyncResourceLoader<Resource>.State, rhs: AsyncResourceLoader<Resource>.State) -> Bool {
        switch (lhs, rhs) {
        case (.notRequested, .notRequested):
            return true
        case (.loading, .loading):
            return true
        case let (.success(lhsResource), .success(rhsResource)):
            return lhsResource == rhsResource
        case (.failure, .failure):
            return true
        default:
            return false
        }
    }
}

extension AsyncResourceLoader.State {
    var isFailure: Bool {
        if case .failure = self {
            return true
        }
        return false
    }
}

