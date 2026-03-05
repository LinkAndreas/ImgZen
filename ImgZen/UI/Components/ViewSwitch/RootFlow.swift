import SwiftUI

struct RootFlow<Onboarding: View, Converter: View>: View {
    enum Step {
        case onboarding
        case converter
    }

    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted: Bool = false

    private let onboarding: (_ completion: @escaping () -> Void) -> Onboarding
    private let converter: () -> Converter

    init(
        @ViewBuilder onboarding: @escaping (_ completion: @escaping () -> Void) -> Onboarding,
        @ViewBuilder converter: @escaping () -> Converter
    ) {
        self.onboarding = onboarding
        self.converter = converter
    }

    var body: some View {
        ZStack {
            if isOnboardingCompleted {
                converter()
                    .transition(.move(edge: .trailing))
            } else {
                onboarding {
                    withAnimation {
                        isOnboardingCompleted = true
                    }
                }
            }
        }
        .animation(.default, value: isOnboardingCompleted)
    }
}
