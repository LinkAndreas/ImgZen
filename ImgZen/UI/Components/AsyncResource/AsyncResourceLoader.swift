import Foundation

/// A generic async resource loader that manages the loading state of a resource.
///
/// This class can be observed for changes and provides an async interface for
/// handling resources that are loaded asynchronously. The loading state is published
/// via the `state` property, which indicates loading progress, success, or failure.
@Observable
public final class AsyncResourceLoader<Resource> {
    /// The async loading closure type that produces a resource or throws an error.
    public typealias Load = @concurrent () async throws -> Resource

    /// Indicates the state of resource loading.
    public enum State {
        /// Indicates no request has been made.
        case notRequested
        /// Indicates the resource is currently being loaded.
        case loading
        /// Indicates the resource was successfully loaded.
        case success(Resource)
        /// Indicates an error occurred while loading the resource.
        case failure(Error)
    }

    /// The current state of the loader.
    public var state: State = .notRequested

    /// The closure to execute when loading the resource.
    private var load: Load

    /// Creates an async resource loader with a given loading closure.
    /// - Parameter load: The closure to execute when loading the resource.
    public init(load: @escaping Load) {
        self.load = load
    }

    /// Initiates loading of the resource asynchronously.
    ///
    /// Updates the `state` property according to the loading status:
    /// - `.loading` when loading begins
    /// - `.success(Resource)` on successful load
    /// - `.failure(Error)` on failure
    public func load() async {
        state = .loading

        do {
            let resource = try await load()
            state = .success(resource)
        } catch {
            state = .failure(error)
        }
    }
}
