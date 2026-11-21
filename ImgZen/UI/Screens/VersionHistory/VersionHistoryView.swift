import SwiftUI

/// Every App Store release of ImgZen, newest first, with what changed in each.
struct VersionHistoryView: View {
    var releases: [Release] = Release.history
    var installedVersion: String = Bundle.main.shortVersion

    var body: some View {
        Form {
            ForEach(releases) { release in
                Section {
                    ReleaseRow(
                        release: release,
                        isInstalled: release.isInstalled(installedVersion: installedVersion)
                    )
                }
            }
        }
        // Tighter than the default, so the releases read as one history rather than separate groups.
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .background { AppBackground() }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .navigationTitle(String(localized: "settings.versionHistory"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        VersionHistoryView(installedVersion: "1.8.1")
    }
    .environment(AppIconStore.preview())
}
#endif
