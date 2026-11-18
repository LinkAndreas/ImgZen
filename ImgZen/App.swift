import SwiftUI
import UIKit

typealias IsOnboardingCompleted = Bool

/// The main entry point for the app.
@main
struct ImgZenApp: App {
    /// The app's icon, which the app takes its logo and colors from, shared by every window.
    @State private var iconStore = AppIconStore.live()

    init() {
        LaunchCleanup.removeLeftovers()
    }

    var body: some Scene {
        WindowGroup {
            RootFlow(
                onboarding: { completion in
                    Onboarding(completion: completion)
                },
                converter: {
                    Converter()
                }
            )
            .environment(iconStore)
            // The app's controls take the icon's main color, and change with it.
            .tint(iconStore.current.palette.accent)
            .environment(\.appAccentColor, iconStore.current.palette.accent)
            // The first frames match the launch screen's plain background; then the icon's colors
            // fade in, so launching doesn't jump.
            .task {
                try? await Task.sleep(for: .milliseconds(150))
                iconStore.showTheme()
            }
        }
    }
}
