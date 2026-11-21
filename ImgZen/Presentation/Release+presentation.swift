import Foundation

extension Release {
    /// "Version 1.8.1".
    var title: String {
        String(format: String(localized: "versionHistory.version"), version)
    }

    /// The month and year the version came out, e.g. "November 2026", in the app's language.
    var formattedDate: String {
        date.formatted(.dateTime.month(.wide).year())
    }
}
