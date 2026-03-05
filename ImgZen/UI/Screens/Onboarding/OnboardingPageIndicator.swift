import SwiftUI

struct OnboardingPageIndicator<Page>: View {
    let pages: [Page]
    @Binding var currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, _ in
                Capsule(style: .continuous)
                    .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.22))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .frame(height: 12)
    }
}
