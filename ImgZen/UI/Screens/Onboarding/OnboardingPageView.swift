import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    /// Whether the page is the one currently shown, used to animate its symbol when it appears.
    var isActive: Bool = true

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: page.systemImageName.rawValue)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 52, weight: .medium))
                .foregroundStyle(.tint)
                .symbolEffect(.bounce, value: isActive)
                .frame(width: 120, height: 120)
                .background {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.18), Color.purple.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingPageView(
        page: OnboardingPage(
            title: "Title",
            subtitle: "Subtitle",
            systemImageName: .lockShield
        )
    )
}
