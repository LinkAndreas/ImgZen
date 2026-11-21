import SwiftUI

/// One release in the version history: its version and month, a subtle mark on the installed version,
/// the line that introduces the notes, and the notes as bullet points.
struct ReleaseRow: View {
    let release: Release
    let isInstalled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(release.title)
                    .font(.headline)

                if isInstalled {
                    InstalledBadge()
                }

                Spacer(minLength: 8)

                Text(release.formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            // The badge takes the version's line; on narrow screens with large text, the date goes below.
            .lineLimit(1)

            if let summary = release.summary {
                Text(summary)
                    .font(.subheadline.weight(.medium))
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(release.notes.indices, id: \.self) { index in
                    ReleaseNote(text: release.notes[index])
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    Form {
        Section {
            ReleaseRow(release: Release.history[0], isInstalled: true)
        }
        Section {
            ReleaseRow(release: Release.history[2], isInstalled: false)
        }
    }
    .environment(AppIconStore.preview())
}
#endif
