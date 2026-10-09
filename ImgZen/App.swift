import SwiftUI
import UIKit

typealias IsOnboardingCompleted = Bool

/// The main entry point for the app.
@main
struct ImgZenApp: App {
    /// Support the Developer purchases, shared by every window.
    @State private var supportStore = SupportStore(service: StoreKitSupportService())
    /// The app's icon, which the app takes its logo and colors from, shared by every window.
    @State private var iconStore = AppIconStore.live()
    @Environment(\.scenePhase) private var scenePhase

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
            .environment(iconStore)
            // The app's controls take the icon's main color, and change with it.
            .tint(iconStore.current.palette.accent)
            .environment(\.appAccentColor, iconStore.current.palette.accent)
            // Finishes purchases that complete outside the purchase flow — Ask to Buy
            // approvals, renewals, purchases on other devices — once per launch.
            .task { supportStore.startObservingTransactions() }
            // Coming back to the app, the subscription may have been cancelled, switched or refunded
            // in Settings, or have run out; a supporter icon goes once recurring support has ended.
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .active { Task { await revertIconIfSupportEnded() } }
            }
            .onChange(of: supportStore.isSupporter) { _, isSupporter in
                if !isSupporter { Task { await revertIconIfSupportEnded() } }
            }
            // The first frames match the launch screen's plain background; then the icon's colors
            // fade in, so launching doesn't jump.
            .task {
                try? await Task.sleep(for: .milliseconds(150))
                iconStore.showTheme()
            }
        }
    }

    /// Goes back to the classic icon, and its colors, once recurring support has ended for sure.
    /// The system tells the user the icon changed. If it can't change now, the next return to
    /// the app tries again.
    private func revertIconIfSupportEnded() async {
        guard iconStore.current != .classic,
              await supportStore.hasRecurringSupportEnded(),
              iconStore.current != .classic
        else { return }
        try? await iconStore.select(.classic)
    }
}
