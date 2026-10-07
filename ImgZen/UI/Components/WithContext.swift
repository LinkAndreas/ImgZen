import SwiftUI

/// A view that provides a context object to its content, built once for the lifetime of the view.
/// Useful for dependency injection in SwiftUI views.
struct WithContext<Object, ContentView: View>: View {
    typealias Content = (Object) -> ContentView

    /// `State(wrappedValue:)` evaluates its argument on every initialization of the view,
    /// so the object is built lazily from the storage that SwiftUI keeps alive instead.
    @State private var storage = WithContextStorage<Object>()
    private let objectBuilder: () -> Object
    private let content: Content

    /// Creates a WithContext view.
    /// - Parameters:
    ///   - objectBuilder: Closure that builds the context object once.
    ///   - content: View builder that receives the context object.
    init(
        _ objectBuilder: @escaping () -> Object,
        @ViewBuilder content: @escaping Content
    ) {
        self.objectBuilder = objectBuilder
        self.content = content
    }

    var body: some View {
        content(storage.object(orBuild: objectBuilder))
    }
}

/// Holds the lazily built context object of a `WithContext` view.
/// Declared outside the generic view so it doesn't depend on its `View` conformance.
final class WithContextStorage<Object> {
    private var object: Object?

    /// Returns the stored object, building it on first access.
    func object(orBuild build: () -> Object) -> Object {
        if let object {
            return object
        }

        let object = build()
        self.object = object
        return object
    }
}
