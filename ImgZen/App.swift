import SwiftUI
import UIKit

typealias IsOnboardingCompleted = Bool

/// The main entry point for the app.
@main
struct ImgZenApp: App {
    /// Support the Developer purchases, shared by every window.
    @State private var supportStore = SupportStore(service: StoreKitSupportService())

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
            .environment(supportStore)
            // Finishes purchases that complete outside the purchase flow — Ask to Buy
            // approvals, renewals, purchases on other devices — once per launch.
            .task { supportStore.startObservingTransactions() }
        }
    }
}
