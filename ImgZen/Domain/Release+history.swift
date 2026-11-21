import Foundation

extension Release {
    /// Every App Store release, newest first, with the notes from the App Store, in the same words as
    /// the version history on the website. Add a new release at the top.
    static let history: [Release] = [
        Release(
            version: "1.9.0",
            year: 2026,
            month: 11,
            summary: "versionHistory.v1_9_0.summary",
            notes: [
                "versionHistory.v1_9_0.note1",
                "versionHistory.v1_9_0.note2",
                "versionHistory.v1_9_0.note3",
            ]
        ),
        Release(
            version: "1.8.1",
            year: 2026,
            month: 11,
            summary: "versionHistory.v1_8_1.summary",
            notes: [
                "versionHistory.v1_8_1.note1",
                "versionHistory.v1_8_1.note2",
                "versionHistory.v1_8_1.note3",
            ]
        ),
        Release(
            version: "1.7.10",
            year: 2026,
            month: 10,
            summary: "versionHistory.v1_7_10.summary",
            notes: [
                "versionHistory.v1_7_10.note1",
                "versionHistory.v1_7_10.note2",
                "versionHistory.v1_7_10.note3",
                "versionHistory.v1_7_10.note4",
                "versionHistory.v1_7_10.note5",
                "versionHistory.v1_7_10.note6",
                "versionHistory.v1_7_10.note7",
                "versionHistory.v1_7_10.note8",
            ]
        ),
        Release(
            version: "1.0.0",
            year: 2026,
            month: 4,
            summary: nil,
            notes: [
                "versionHistory.v1_0_0.note1",
                "versionHistory.v1_0_0.note2",
                "versionHistory.v1_0_0.note3",
            ]
        ),
    ]
}
