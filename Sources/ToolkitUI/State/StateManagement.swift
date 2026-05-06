import Foundation
import SwiftUI
import Combine

// MARK: - State Management Documentation

/**
 # AsyncState
 
 A generic enum representing the lifecycle of an asynchronous operation.
 It is commonly used in ViewModels to track data fetching status.
 
 ## Usage
 ```swift
 @Published var state: AsyncState<[User]> = .idle
 
 func fetch() async {
     state = .loading
     do {
         let users = try await api.getUsers()
         state = .success(users)
     } catch {
         state = .failure(error)
     }
 }
 ```
 */
public enum AsyncState<T>: Sendable where T: Sendable {
    /// No operation has started.
    case idle
    /// Operation is currently in progress.
    case loading
    /// Operation completed successfully with a payload.
    case success(T)
    /// Operation failed with an error.
    case failure(Error)

    /// Returns `true` if the state is `.loading`.
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    /// Returns the success payload if available.
    public var value: T? {
        if case .success(let v) = self { return v }
        return nil
    }

    /// Returns the error if the operation failed.
    public var error: Error? {
        if case .failure(let e) = self { return e }
        return nil
    }
}

// MARK: - Base ViewModel Documentation

/**
 # TKViewModel
 
 A base class for all view models in the Toolkit.
 It provides standard properties for loading and error states, and a helper `run` method
 to execute async operations safely on the `MainActor`.
 
 ## Usage
 ```swift
 class UserListViewModel: TKViewModel {
     func load() {
         run {
             self.users = try await service.fetch()
         }
     }
 }
 ```
 */
@MainActor
open class TKViewModel: ObservableObject {
    /// Indicates if a background operation is active.
    @Published public var isLoading: Bool = false
    /// Stores the last error message for UI display.
    @Published public var errorMessage: String? = nil
    /// Stores a success message (e.g., "Saved successfully").
    @Published public var successMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()

    public init() {}

    /// Manually sets the loading state.
    internal func setLoading(_ loading: Bool) { isLoading = loading }
    
    /// Manually sets an error message.
    internal func setError(_ message: String) { errorMessage = message }
    
    /// Resets all state properties to their defaults.
    internal func clearState() { isLoading = false; errorMessage = nil; successMessage = nil }

    /**
     Executes an asynchronous operation on the MainActor, automatically managing
     loading and error states.
     - Parameter operation: The async block to execute.
     */
    internal func run(_ operation: @escaping @MainActor () async throws -> Void) {
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
            do {
                try await operation()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Global State Documentation

/**
 # GlobalStateContainer
 
 A thread-safe, singleton key-value store for sharing state across different parts
 of the application that are not directly related in the view hierarchy.
 
 ## Usage
 ```swift
 GlobalStateContainer.shared.set("John", for: "username")
 
 let name = GlobalStateContainer.shared.get("username", as: String.self)
 ```
 */
@MainActor
public final class GlobalStateContainer: ObservableObject, Sendable {
    /// Shared singleton instance.
    public static let shared = GlobalStateContainer()

    private var state: [String: Any] = [:]
    private let lock = NSLock()

    public init() {}

    /**
     Stores a value for a specific key.
     */
    public func set<T>(_ value: T, for key: String) {
        lock.lock(); defer { lock.unlock() }
        state[key] = value
        DispatchQueue.main.async { self.objectWillChange.send() }
    }

    /**
     Retrieves a value for a specific key, cast to the expected type.
     */
    public func get<T>(_ key: String, as type: T.Type) -> T? {
        lock.lock(); defer { lock.unlock() }
        return state[key] as? T
    }

    /// Removes a value from the container.
    public func remove(key: String) {
        lock.lock(); defer { lock.unlock() }
        state.removeValue(forKey: key)
        DispatchQueue.main.async { self.objectWillChange.send() }
    }
}
