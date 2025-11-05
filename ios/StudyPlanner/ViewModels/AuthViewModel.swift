import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService = AuthService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Check authentication status on init
        authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.isAuthenticated = user != nil
                self?.currentUser = user
            }
            .store(in: &cancellables)
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.signUp(email: email, password: password, displayName: displayName)
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.signInWithGoogle()
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() {
        authService.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.resetPassword(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}