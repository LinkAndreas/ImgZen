import SwiftUI

struct OnboardingPageView: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    let page: OnboardingPage

    var body: some View {
        VStack {
            Spacer(minLength: 0)

            VStack(spacing: 14) {
                Image(systemName: page.systemImageName.rawValue)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 72, weight: .regular))
                    .foregroundStyle(.tint)
                    .padding(.bottom, 6)

                Text(page.title)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
            .background(Color.secondarySystemGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
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
