import SwiftUI

/// A view that provides a context object to its content, built once on initialization.
/// Useful for dependency injection in SwiftUI views.
struct WithContext<Object, ContentView: View>: View {
    typealias Content = (Object) -> ContentView

    @State private var object: Object
    private let content: Content

    /// Creates a WithContext view.
    /// - Parameters:
    ///   - objectBuilder: Closure that builds the context object once.
    ///   - content: View builder that receives the context object.
    init(
        _ objectBuilder: @escaping () -> Object,
        @ViewBuilder content: @escaping Content
    ) {
        self._object = State(wrappedValue: objectBuilder())
        self.content = content
    }

    var body: some View {
        content(object)
    }
}
