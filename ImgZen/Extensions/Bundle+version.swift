import Foundation

extension Bundle {
    /// The app's version as people see it in the App Store, e.g. "1.8.1".
    nonisolated var shortVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    /// The build number of the app's version.
    nonisolated var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}
