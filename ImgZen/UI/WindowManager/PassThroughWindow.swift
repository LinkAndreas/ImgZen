import UIKit

/// A UIWindow subclass that allows touches to pass through to views behind it, except for interactive content.
final class PassThroughWindow: UIWindow {
    /// Overrides hit testing to allow touches to pass through transparent areas.
    /// - Parameters:
    ///   - point: The point to test.
    ///   - event: The event associated with the hit test.
    /// - Returns: The view that should handle the touch, or nil to pass through.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let rootView = rootViewController?.view else {
            return nil
        }

        if rootView.layer.hitTest(point)?.name == nil {
            return rootView
        } else {
            return nil
        }
    }
}