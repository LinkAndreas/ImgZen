import SwiftUI

struct ViewSwitch<First: View, Second: View>: View {
    @Binding private var activeView: ActiveView

    private let transition: AnyTransition
    private let first: () -> First
    private let second: () -> Second

    init(
        activeView: Binding<ActiveView>,
        transition: AnyTransition = .move(edge: .trailing),
        @ViewBuilder first: @escaping () -> First,
        @ViewBuilder second: @escaping () -> Second
    ) {
        _activeView = activeView
        self.transition = transition
        self.first = first
        self.second = second
    }

    var body: some View {
        ZStack {
            switch activeView {
            case .first:
                first()
            case .second:
                second()
                    .transition(transition)
            }
        }
        .animation(.default, value: activeView)
    }
}
