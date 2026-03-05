import SwiftUI
import UIKit

typealias IsOnboardingCompleted = Bool

/// The main entry point for the app.
@main
struct ImgZenApp: App {
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
        }
    }
}
