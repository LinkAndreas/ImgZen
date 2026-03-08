import SwiftUI

struct Onboarding: View {
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

    var body: some View {
        NavigationStack {
            ZStack {
                Color.systemBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120)
                        .containerRelativeFrame(.vertical, alignment: .bottom) { length, _ in
                            length * 0.25
                        }

                    TabView(selection: $viewModel.currentPage) {
                        ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                            OnboardingPageView(page: page)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.25), value: viewModel.currentPage)

                    Spacer()

                    OnboardingPageIndicator(
                        pages: viewModel.pages,
                        currentPage: $viewModel.currentPage
                    )
                    .padding(.top, 10)

                    Button(action: viewModel.advance) {
                        Text(viewModel.bottomButtonTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
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
