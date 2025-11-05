import Foundation
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import Combine

class AuthService: NSObject {
    static let shared = AuthService()

    private let auth = Auth.auth()
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    var authStatePublisher = PassthroughSubject<User?, Never>()

    override init() {
        super.init()
        setupAuthListener()
    }

    private func setupAuthListener() {
        authStateHandle = auth.addStateDidChangeListener { [weak self] _, user in
            self?.authStatePublisher.send(user)
        }
    }

    deinit {
        if let handle = authStateHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }

    func signIn(email: String, password: String) async throws -> User {
        let authResult = try await auth.signIn(withEmail: email, password: password)
        return authResult.user
    }

    func signUp(email: String, password: String, displayName: String) async throws -> User {
        let authResult = try await auth.createUser(withEmail: email, password: password)

        let changeRequest = authResult.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()

        return authResult.user
    }

    func signInWithGoogle() async throws -> User {
        guard let presentingViewController = UIApplication.shared.keyWindow?.rootViewController else {
            throw AuthError.noPresentingViewController
        }

        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let result = result else {
                    continuation.resume(throwing: AuthError.googleSignInFailed)
                    return
                }

                let idToken = result.user.idToken?.tokenString
                let accessToken = result.user.accessToken.tokenString

                let credential = GoogleAuthProvider.credential(withIDToken: idToken!, accessToken: accessToken)

                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    if let user = authResult?.user {
                        continuation.resume(returning: user)
                    } else {
                        continuation.resume(throwing: AuthError.googleSignInFailed)
                    }
                }
            }
        }
    }

    func signInWithApple() async throws -> User {
        // Apple Sign In implementation
        throw AuthError.notImplemented
    }

    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    func signOut() {
        do {
            try auth.signOut()
            GIDSignIn.sharedInstance.signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    func updateUserProfile(displayName: String?, photoURL: URL?) async throws {
        guard let user = auth.currentUser else {
            throw AuthError.userNotSignedIn
        }

        let changeRequest = user.createProfileChangeRequest()
        if let displayName = displayName {
            changeRequest.displayName = displayName
        }
        if let photoURL = photoURL {
            changeRequest.photoURL = photoURL
        }

        try await changeRequest.commitChanges()
    }
}

enum AuthError: LocalizedError {
    case userNotSignedIn
    case googleSignInFailed
    case appleSignInFailed
    case noPresentingViewController
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .userNotSignedIn:
            return "User is not signed in"
        case .googleSignInFailed:
            return "Google sign in failed"
        case .appleSignInFailed:
            return "Apple sign in failed"
        case .noPresentingViewController:
            return "No presenting view controller available"
        case .notImplemented:
            return "This feature is not implemented yet"
        }
    }
}