import SwiftUI

struct RootFlow<Onboarding: View, Converter: View>: View {
    enum Step {
        case onboarding
        case converter
    }

    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted: Bool = false
    /// The version of What's New last shown; new users get the onboarding instead of it.
    @AppStorage("lastSeenWhatsNew") private var lastSeenWhatsNew: String?

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
                // A crossfade, since sliding in a navigation stack makes its large title jump into place.
                converter()
                    .transition(.opacity)
            } else {
                onboarding {
                    // The onboarding introduces the app as it is, so What's New isn't shown after it.
                    lastSeenWhatsNew = WhatsNew.version
                    withAnimation {
                        isOnboardingCompleted = true
                    }
                }
            }
        }
        .animation(.default, value: isOnboardingCompleted)
    }
}
