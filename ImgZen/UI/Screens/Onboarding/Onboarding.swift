import SwiftUI

struct Onboarding: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State private var viewModel: OnboardingViewModel

    init(
        pages: [OnboardingPage] = .standard,
        completion: @escaping () -> Void = {}
    ) {
        _viewModel = State(
            wrappedValue: OnboardingViewModel(
                pages: pages,
                completion: completion
            )
        )
    }

    private var isRegular: Bool {
        horizontalSizeClass == .regular
    }

    private var logo: some View {
        Image("Logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 96)
            .accessibilityHidden(true)
    }

    var body: some View {
        ZStack {
            Color.systemBackground
                .ignoresSafeArea()

            // A soft wash in the logo's colors gives the screen depth without boxing the content in.
            LinearGradient(
                colors: [Color.accentColor.opacity(0.14), Color.purple.opacity(0.08), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if isRegular {
                    // Center logo and page in the space above the controls, which stay at the bottom
                    // edge of large screens so they're within thumb reach while holding the iPad.
                    Spacer()

                    logo
                        .padding(.bottom, 12)
                } else {
                    logo
                        .containerRelativeFrame(.vertical, alignment: .bottom) { length, _ in
                            length * 0.25
                        }
                }

                TabView(selection: $viewModel.currentPage) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, isActive: viewModel.currentPage == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: viewModel.currentPage)
                .frame(maxHeight: isRegular ? 340 : .infinity)

                Spacer()

                OnboardingPageIndicator(
                    pages: viewModel.pages,
                    currentPage: $viewModel.currentPage
                )
                .padding(.top, 10)

                Button(action: viewModel.advance) {
                    Text(viewModel.bottomButtonTitle)
                        .frame(maxWidth: isRegular ? 350 : .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .padding(.horizontal, 20)
                .padding(.top, 14)

                // Skip sits below the main button instead of in the top corner, so both stay within thumb reach.
                // It keeps its space on the last page so the main button doesn't move.
                Button(action: viewModel.completion) {
                    Text(String(localized: "button.skip"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 88, minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .padding(.bottom, isRegular ? 24 : 8)
                .opacity(viewModel.isLastPage ? 0 : 1)
                .disabled(viewModel.isLastPage)
                .accessibilityHidden(viewModel.isLastPage)
            }
        }
    }
}

#Preview {
    Onboarding()
}
