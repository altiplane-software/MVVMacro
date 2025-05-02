import XCTest

@MainActor
final class MVVMacroTests: XCTestCase, @unchecked Sendable {
    var viewModel: TestViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = TestViewModel()
    }
    
    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.counter, 0, "Counter should start at 0")
    }
    
    func testIncrement() {
        // Test incrementing by 1
        viewModel.send(.increment(1))
        XCTAssertEqual(viewModel.counter, 1, "Counter should be 1 after incrementing by 1")
        
        // Test incrementing by 5
        viewModel.send(.increment(5))
        XCTAssertEqual(viewModel.counter, 6, "Counter should be 6 after incrementing by 5")
    }
    
    func testDecrement() {
        // Test decrementing by 1
        viewModel.send(.decrement(1))
        XCTAssertEqual(viewModel.counter, -1, "Counter should be -1 after decrementing by 1")
        
        // Test decrementing by 5
        viewModel.send(.decrement(5))
        XCTAssertEqual(viewModel.counter, -6, "Counter should be -6 after decrementing by 5")
    }
    
    func testReset() {
        // First increment the counter
        viewModel.send(.increment(10))
        XCTAssertEqual(viewModel.counter, 10, "Counter should be 10 after incrementing")
        
        // Then reset it
        viewModel.send(.reset)
        XCTAssertEqual(viewModel.counter, 0, "Counter should be 0 after reset")
    }
    
    func testMultipleOperations() {
        // Test a sequence of operations
        viewModel.send(.increment(5))  // 5
        viewModel.send(.decrement(2))  // 3
        viewModel.send(.increment(7))  // 10
        viewModel.send(.decrement(3))  // 7
        viewModel.send(.reset)         // 0
        viewModel.send(.increment(1))  // 1
        
        XCTAssertEqual(viewModel.counter, 1, "Counter should be 1 after sequence of operations")
    }
    
}
