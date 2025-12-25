import SwiftUI

extension View {
    /**
     Performs the given action when the view appears for the first time.
     
     - Parameter perform: The action that is performed when the view appears for the first time.
     */
    public func onFirstAppear(perform: @escaping () -> Void) -> some View {
        modifier(OnFirstAppear(perform: perform))
    }
}

/// ViewModifier that executes an action only on the first appearance of a view.
private struct OnFirstAppear: ViewModifier {
    @State private var isFirstAppear = true

    private let perform: () -> Void

    /// Creates the modifier with an action to perform.
    /// - Parameter perform: The action to execute on first appearance.
    public init(perform: @escaping () -> Void) {
        self.perform = perform
    }

    /// Applies the modifier, executing the action only on first appearance.
    public func body(content: Content) -> some View {
        content.onAppear {
            if isFirstAppear {
                isFirstAppear = false
                perform()
            }
        }
    }
}
