import SwiftUI
import UIKit

typealias IsOnboardingCompleted = Bool

/// The main entry point for the app.
@main
struct ImgZenApp: App {
    @AppStorage("isOnboardingCompleted")
    private var isOnboardingCompleted: IsOnboardingCompleted = false

    var body: some Scene {
        WindowGroup {
            ViewSwitch(
                activeView: $isOnboardingCompleted.activeView,
                first: {
                    OnboardingView(
                        completion: {
                            withAnimation {
                                isOnboardingCompleted = true
                            }
                        }
                    )
                },
                second: {
                    ContentView()
                }
            )
        }
    }
}

extension IsOnboardingCompleted {
    var activeView: ActiveView {
        get { self ? .second : .first }
        set {}
    }
}
