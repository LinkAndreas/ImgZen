import SwiftUI

// Helpers for the split arrangements of iPhone Duo (iOS 27.1), which place two views beside each
// other or above each other, depending on the shape of the display, and avoid the fold.

extension View {
    /// Calls the action with whether the view is shown in a split arrangement next to another view,
    /// initially and on changes. An arrangement can collapse to a single view when space runs short.
    func onSplitArrangementChange(_ action: @escaping (_ isSplit: Bool) -> Void) -> some View {
        background {
            if #available(iOS 27.1, *) {
                SplitArrangementObserver(action: action)
            }
        }
    }
}

@available(iOS 27.1, *)
private struct SplitArrangementObserver: View {
    @Environment(\.splitArrangementAxis) private var splitAxis
    let action: (Bool) -> Void

    var body: some View {
        Color.clear
            .onChange(of: splitAxis != nil, initial: true) { _, isSplit in
                action(isSplit)
            }
    }
}
