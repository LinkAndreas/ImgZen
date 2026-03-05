import Foundation

extension [OnboardingPage] {
    static let standard: [OnboardingPage] = [
        OnboardingPage(
            title: String(localized: "onboarding.convert.title"),
            subtitle: String(localized: "onboarding.convert.subtitle"),
            systemImageName: .arrowCircle
        ),
        OnboardingPage(
            title: String(localized: "onboarding.batchAndQuality.title"),
            subtitle: String(localized: "onboarding.batchAndQuality.subtitle"),
            systemImageName: .stack
        ),
        OnboardingPage(
            title: String(localized: "onboarding.sharePrivately.title"),
            subtitle: String(localized: "onboarding.sharePrivately.subtitle"),
            systemImageName: .lockShield
        )
    ]
}
