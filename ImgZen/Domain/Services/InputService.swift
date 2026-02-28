import Observation
import Foundation

/// Service for managing a collection of input items for processing.
@Observable
final class InputService: Sendable {
    /// The current collection of input items.
    var items: [InputItem] = []

    /// Creates an empty InputService.
    init() {}

    // MARK: - Item

    /// Adds new items to the collection.
    /// - Parameter items: The items to add.
    func didAdd(items: [InputItem]) {
        self.items += items
    }

    /// Removes specified items from the collection.
    /// - Parameter items: The items to remove.
    func didRemove(items: [InputItem]) {
        self.items.removeAll { items.map(\.id).contains($0.id) }
    }
    
    /// Removes all items from the collection.
    func removeAll() {
        items.removeAll()
    }
}
