import SwiftUI

/// A note of a release as a bullet point, with lines after the first aligned to the text.
struct ReleaseNote: View {
    let text: LocalizedStringResource

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(verbatim: "•")
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text(text)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.subheadline)
    }
}

#if DEBUG
#Preview {
    ReleaseNote(text: Release.history[0].notes[0])
        .padding()
}
#endif
