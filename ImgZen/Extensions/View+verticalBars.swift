import SwiftUI

// Helpers for the vertical bars of iPhone Duo (iOS 27.1), where navigation and toolbar items move
// into a bar along the side of the display. They fall back to regular bars on earlier systems.

extension View {
    /// Adds a screen's prominent action, e.g. Done or Send, in the pinned trailing placement:
    /// on iPhone Duo it stays at the top of the vertical bar instead of scrolling away with the title,
    /// and with a high visibility priority, it's the last item to move into the overflow menu.
    @ViewBuilder
    func toolbarProminentAction<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if #available(iOS 27.1, *) {
            toolbar {
                ToolbarItem(placement: .topBarPinnedTrailing, content: content)
                    .visibilityPriority(.high)
            }
        } else {
            toolbar {
                ToolbarItem(placement: .topBarTrailing, content: content)
            }
        }
    }

    /// Adds toolbar items whose content adapts to the vertical bar, so they join it instead of
    /// staying in a horizontal bar. Use it for items with custom labels that read `VerticalBarReader`.
    @ViewBuilder
    func toolbarPreferringVerticalBar<Content: ToolbarContent>(
        @ToolbarContentBuilder _ content: () -> Content
    ) -> some View {
        if #available(iOS 27.1, *) {
            toolbar {
                content()
                    .axisBehavior(.verticalPreferred)
            }
        } else {
            toolbar(content: content)
        }
    }

    /// Adds secondary actions to the toolbar's overflow menu, which iPhone Duo shares with the items
    /// that don't fit the vertical bar. Earlier systems show them in an ellipsis menu at the top.
    @ViewBuilder
    func toolbarOverflowMenu<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if #available(iOS 27.1, *) {
            toolbar {
                ToolbarOverflowMenu {
                    content()
                }
            }
        } else {
            toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu(title, systemImage: "ellipsis", content: content)
                }
            }
        }
    }

    /// Calls the action with whether the bars of the view are shown vertically, initially and on changes.
    func onVerticalBarChange(_ action: @escaping (Bool) -> Void) -> some View {
        background {
            if #available(iOS 27.1, *) {
                VerticalBarObserver(action: action)
            }
        }
    }
}

/// Gives its content whether the bar it's in is vertical, so a toolbar item can arrange
/// its label for the fixed width of a vertical bar.
struct VerticalBarReader<Content: View>: View {
    private let content: (Bool) -> Content

    init(@ViewBuilder content: @escaping (_ isVertical: Bool) -> Content) {
        self.content = content
    }

    var body: some View {
        if #available(iOS 27.1, *) {
            VerticalBarEdgeReader(content: content)
        } else {
            content(false)
        }
    }
}

@available(iOS 27.1, *)
private struct VerticalBarEdgeReader<Content: View>: View {
    @Environment(\.toolbarVerticalEdge) private var verticalEdge
    let content: (Bool) -> Content

    var body: some View {
        content(verticalEdge != nil)
    }
}

@available(iOS 27.1, *)
private struct VerticalBarObserver: View {
    @Environment(\.toolbarVerticalEdge) private var verticalEdge
    let action: (Bool) -> Void

    var body: some View {
        Color.clear
            .onChange(of: verticalEdge != nil, initial: true) { _, isVertical in
                action(isVertical)
            }
    }
}
