import Foundation
import Observation

@Observable
final class OnboardingViewModel {
    var isLastPage: Bool {
        currentPage == pages.count - 1
    }

    var bottomButtonTitle: String {
        if isLastPage {
            String(localized: "button.startConverting")
        } else {
            String(localized: "button.next")
        }
    }

    var currentPage: Int = 0
    let pages: [OnboardingPage]
    let completion: () -> Void

    init(
        pages: [OnboardingPage] = .standard,
        completion: @escaping () -> Void
    ) {
        self.pages = pages
        self.completion = completion
    }

    func advance() {
        if currentPage < pages.count - 1 {
            currentPage += 1
        } else {
            completion()
        }
    }
}
