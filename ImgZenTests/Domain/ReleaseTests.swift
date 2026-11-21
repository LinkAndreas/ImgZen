import Foundation
import Testing
@testable import ImgZen

struct ReleaseTests {

    @Test("The version history lists every release once, newest first")
    func testHistoryIsNewestFirst() {
        let history = Release.history
        #expect(Set(history.map(\.version)).count == history.count)
        for (newer, older) in zip(history, history.dropFirst()) {
            #expect(newer.isNewer(than: older), "\(newer.version) should come before \(older.version)")
            #expect(newer.date >= older.date, "\(newer.version) should not be older than \(older.version)")
        }
    }

    @Test("Every release has notes")
    func testEveryReleaseHasNotes() {
        for release in Release.history {
            #expect(!release.notes.isEmpty, "\(release.version) has no notes")
        }
    }

    @Test("Versions compare their parts as numbers")
    func testNumericVersionComparison() {
        let older = Release(version: "1.7.9", year: 2026, month: 9, summary: nil, notes: [])
        let newer = Release(version: "1.7.10", year: 2026, month: 10, summary: nil, notes: [])
        #expect(newer.isNewer(than: older))
        #expect(!older.isNewer(than: newer))
    }

    @Test("Only the version running on the device is marked as installed")
    func testInstalledVersion() {
        let release = Release(version: "1.8.1", year: 2026, month: 11, summary: nil, notes: [])
        #expect(release.isInstalled(installedVersion: "1.8.1"))
        #expect(!release.isInstalled(installedVersion: "1.8.2"))
    }
}
