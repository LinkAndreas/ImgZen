import Foundation

/// A version of ImgZen released on the App Store, with its release notes.
nonisolated struct Release: Identifiable, Sendable {
    /// The version as the App Store shows it, e.g. "1.8.1".
    let version: String
    /// The year and month the version came out.
    let year: Int
    let month: Int
    /// The line that introduces the notes, if the release has one.
    let summary: LocalizedStringResource?
    /// The release notes, one per point.
    let notes: [LocalizedStringResource]

    var id: String { version }

    /// The first day of the month the version came out.
    var date: Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: 1)) ?? .distantPast
    }

    /// Whether this is the version running on the device.
    /// - Parameter installedVersion: The version of the running app, e.g. `Bundle.main.shortVersion`.
    func isInstalled(installedVersion: String) -> Bool {
        version == installedVersion
    }
}

extension Release {
    /// Whether this version is newer than `other`, comparing the parts of the version as numbers,
    /// so 1.7.10 is newer than 1.7.9.
    func isNewer(than other: Release) -> Bool {
        version.compare(other.version, options: .numeric) == .orderedDescending
    }
}
