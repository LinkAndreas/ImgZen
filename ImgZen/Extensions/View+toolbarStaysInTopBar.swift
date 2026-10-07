import SwiftUI

extension View {
    /// Keeps the toolbar in the top bar on devices with a vertical bar (e.g. iPhone Duo).
    /// A sheet only receives the vertical bar inset once it reaches the top of the screen,
    /// so its toolbar items would otherwise jump from the top bar to the vertical bar while it's presented.
    /// Apply it to the content of a sheet.
    @ViewBuilder
    func toolbarStaysInTopBar() -> some View {
        if #available(iOS 27.1, *) {
            toolbarVerticalBehavior(.disabled)
        } else {
            self
        }
    }
}
