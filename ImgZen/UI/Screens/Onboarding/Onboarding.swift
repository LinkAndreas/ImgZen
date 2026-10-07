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
            .frame(width: 120)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.systemBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    if isRegular {
                        // Keep logo, page and controls together in the middle of large screens.
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
                            OnboardingPageView(page: page)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.25), value: viewModel.currentPage)
                    .frame(maxHeight: isRegular ? 380 : .infinity)

                    if !isRegular {
                        Spacer()
                    }

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
                    .padding(.bottom, 24)

                    if isRegular {
                        Spacer()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("button.skip", action: viewModel.completion)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    Onboarding()
}
