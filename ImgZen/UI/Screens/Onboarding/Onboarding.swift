import SwiftUI

struct Onboarding: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @State private var viewModel: OnboardingViewModel
    /// The height of the controls at the bottom, so the pages can keep their content clear of them.
    @State private var controlsHeight: CGFloat = 0

    private static let logoSize: CGFloat = 96
    private static let logoSpacing: CGFloat = 12
    private static let regularPageHeight: CGFloat = 340

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
        AppLogo(size: Self.logoSize)
    }

    var body: some View {
        ZStack {
            // A soft wash in the logo's colors gives the screen depth without boxing the content in.
            AppBackground()

            GeometryReader { geometry in
                let layout = Layout(
                    height: geometry.size.height,
                    controlsHeight: controlsHeight,
                    isRegular: isRegular
                )

                ZStack(alignment: .top) {
                    // The pages fill the whole screen, so a swipe anywhere turns the page,
                    // not only on the text in the middle.
                    TabView(selection: $viewModel.currentPage) {
                        ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                            OnboardingPageView(page: page, isActive: viewModel.currentPage == index)
                                .frame(height: layout.pageHeight)
                                .padding(.top, layout.pageTop)
                                .frame(maxHeight: .infinity, alignment: .top)
                                .contentShape(.rect)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.25), value: viewModel.currentPage)

                    // The logo stays put while the pages move beneath it; it lets swipes through.
                    logo
                        .padding(.top, layout.logoTop)
                        .allowsHitTesting(false)

                    // Measured before it's pinned to the bottom, so this is the height of the controls alone.
                    controls
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.size.height
                        } action: { height in
                            controlsHeight = height
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
    }

    /// Indicator, main button and Skip, at the bottom edge so they're within thumb reach on every device.
    private var controls: some View {
        VStack(spacing: 0) {
            OnboardingPageIndicator(
                pages: viewModel.pages,
                currentPage: $viewModel.currentPage
            )
            .padding(.top, 10)
            .allowsHitTesting(false)

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

    /// Where the logo and page content go, so the floating logo and the swipeable pages line up.
    private struct Layout {
        let logoTop: CGFloat
        let pageTop: CGFloat
        let pageHeight: CGFloat

        init(height: CGFloat, controlsHeight: CGFloat, isRegular: Bool) {
            let available = max(0, height - controlsHeight)

            if isRegular {
                // Center logo and page in the space above the controls on large screens.
                let groupHeight = Onboarding.logoSize + Onboarding.logoSpacing + Onboarding.regularPageHeight
                let top = max(0, (available - groupHeight) / 2)
                logoTop = top
                pageTop = top + Onboarding.logoSize + Onboarding.logoSpacing
                pageHeight = min(Onboarding.regularPageHeight, max(0, available - pageTop))
            } else {
                // The logo ends a quarter down the screen; the page fills the space up to the controls.
                let logoBottom = max(Onboarding.logoSize, height * 0.25)
                logoTop = logoBottom - Onboarding.logoSize
                pageTop = logoBottom
                pageHeight = max(0, available - logoBottom)
            }
        }
    }
}

#if DEBUG
#Preview {
    Onboarding()
        .environment(AppIconStore.preview())
}
#endif
