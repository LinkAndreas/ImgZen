import Observation
import UIKit

/// The icon ImgZen shows on the Home Screen, which the app takes its logo, accent color and
/// background from.
@Observable
final class AppIconStore {
    /// The app's icon.
    private(set) var current: SupporterIcon

    /// The icon whose colors the background shows. It starts without one, plain like the launch screen,
    /// and follows `current` once the app is on screen, so launching blends into the icon's colors.
    private(set) var theme: SupporterIcon?

    private let setAlternateIconName: (String?) async throws -> Void

    /// - Parameters:
    ///   - alternateIconName: The app's alternate icon, as `UIApplication.alternateIconName` gives it.
    ///   - setAlternateIconName: Changes the app's icon, as `UIApplication.setAlternateIconName` does.
    init(
        alternateIconName: String?,
        setAlternateIconName: @escaping (String?) async throws -> Void
    ) {
        current = SupporterIcon(alternateIconName: alternateIconName)
        self.setAlternateIconName = setAlternateIconName
    }

    /// Switches from the launch screen's plain background to the icon's colors.
    func showTheme() {
        theme = current
    }

    /// Makes `icon` the app's icon. The app follows right away and goes back if the system refuses.
    func select(_ icon: SupporterIcon) async throws {
        guard icon != current else { return }

        let previous = current
        current = icon
        theme = icon
        do {
            try await setAlternateIconName(icon.alternateIconName)
        } catch {
            current = previous
            theme = previous
            throw error
        }
    }
}

extension AppIconStore {
    /// The store for the app's real icon.
    static func live() -> AppIconStore {
        AppIconStore(alternateIconName: UIApplication.shared.alternateIconName) { name in
            try await UIApplication.shared.setAlternateIconName(name)
        }
    }

    #if DEBUG
    /// A store for previews, which can't change the app's icon.
    static func preview(_ icon: SupporterIcon = .classic) -> AppIconStore {
        let store = AppIconStore(alternateIconName: icon.alternateIconName) { _ in }
        store.showTheme()
        return store
    }
    #endif
}
