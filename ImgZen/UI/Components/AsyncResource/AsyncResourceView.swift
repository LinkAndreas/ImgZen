import SwiftUI

/// A view that manages and displays content for an asynchronous resource.
/// Handles the resource loading state and displays appropriate views for loading, failure, or success scenarios.
/// - Parameters:
///   - Resource: The type of resource being loaded and displayed.
public struct AsyncResourceView<Resource>: View {
    public typealias Loader = AsyncResourceLoader<Resource>

    @State private var loader: Loader

    private var notRequestedView: (@escaping () -> Void) -> AnyView
    private var loadingView: () -> AnyView
    private var failureView: (Error, @escaping () -> Void) -> AnyView
    private var successView: (Resource) -> AnyView

    /// Creates an AsyncResourceView.
    /// - Parameters:
    ///   - load: An async closure for loading the resource.
    ///   - notRequestedView: View to show before resource is requested. Default provides a basic not-requested view.
    ///   - loadingView: View to show while loading. Default provides a spinner.
    ///   - failureView: View to show if loading fails. Default provides a retry option.
    ///   - successView: View to show when resource loads successfully.
    public init(
        load: @concurrent @escaping () async throws -> Resource,
        @ViewBuilder notRequestedView: @escaping (@escaping () -> Void) -> some View = { AnyView(AsyncResourceDefaultNotRequestedView(load: $0)) },
        @ViewBuilder loadingView: @escaping () -> some View = { AnyView(AsyncResourceDefaultLoadingView()) },
        @ViewBuilder failureView: @escaping (Error, @escaping () -> Void) -> some View = { AnyView(AsyncResourceDefaultFailureView(error: $0, retry: $1)) },
        @ViewBuilder successView: @escaping (Resource) -> some View
    ) {
        self.loader = Loader(load: load)
        self.notRequestedView = { refresh in AnyView(notRequestedView(refresh)) }
        self.loadingView = { AnyView(loadingView()) }
        self.failureView = { error, retry in AnyView(failureView(error, retry)) }
        self.successView = { resource in AnyView(successView(resource)) }
    }

    /// The main view content. Displays the appropriate subview depending on the resource loading state.
    public var body: some View {
        switch loader.state {
        case .notRequested:
            return notRequestedView(loadResource)

        case .loading:
            return loadingView()

        case let .success(resource):
            return successView(resource)

        case let .failure(error):
            return failureView(error, loadResource)
        }
    }

    /// Triggers (re)loading the asynchronous resource.
    private func loadResource() {
        Task.detached { @concurrent in
            await loader.load()
        }
    }
}

/// Default view to be shown when an async resource hasn't been requested yet.
public struct AsyncResourceDefaultNotRequestedView: View {
    private let load: () -> Void

    /// Creates the default not requested view.
    /// - Parameter load: Action to start loading the resource.
    public init(load: @escaping () -> Void) {
        self.load = load
    }

    /// The placeholder body that triggers loading on first appear.
    public var body: some View {
        Color.clear
            .onFirstAppear(perform: load)
    }
}

/// Default view for displaying a loading spinner during async resource loading.
public struct AsyncResourceDefaultLoadingView: View {
    private let title: String

    /// Creates a loading view.
    /// - Parameter title: The title shown with the loading spinner. Defaults to "Loading".
    public init(title: String = "Loading") {
        self.title = title
    }

    public var body: some View {
        ProgressView(title)
    }
}

/// Default view that presents an error and retry option upon failed async resource load.
public struct AsyncResourceDefaultFailureView: View {
    private let error: Error
    private let retry: () -> Void

    /// Creates a failure view.
    /// - Parameters:
    ///   - error: The error encountered while loading.
    ///   - retry: Action to retry loading.
    public init(error: Error, retry: @escaping () -> Void) {
        self.error = error
        self.retry = retry
    }

    /// The body for the default failure view, presenting the error and a retry button.
    public var body: some View {
        VStack(spacing: 16) {
            Text(String(reflecting: error))
            Button(action: retry) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 25))
                    .tint(.accentColor)
            }
        }
    }
}
