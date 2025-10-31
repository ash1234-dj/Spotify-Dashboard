//
//  AuthenticationManager.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 25/10/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import AuthenticationServices
import CryptoKit

// Conditional import - only available when GoogleSignIn SDK is added
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

// MARK: - User Model

struct AppUser: Codable {
    let id: String
    let email: String
    let displayName: String
    let photoURL: String?
    let provider: AuthProvider
    let createdAt: Date
    
    enum AuthProvider: String, Codable, CaseIterable {
        case apple = "apple"
        case google = "google"
        case guest = "guest"
        
        var displayName: String {
            switch self {
            case .apple: return "Apple"
            case .google: return "Google"
            case .guest: return "Guest"
            }
        }
        
        var icon: String {
            switch self {
            case .apple: return "applelogo"
            case .google: return "globe"
            case .guest: return "person.circle"
            }
        }
    }
}

// MARK: - Authentication Manager

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var user: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Listen for authentication state changes
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.createAppUser(from: user)
                } else {
                    self?.user = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Check Apple ID credential state first
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            
            // Create the authorization request
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            // Generate and set nonce for security
            let nonce = randomNonceString()
            request.nonce = sha256(nonce)
            
            print("🍎 Starting Apple Sign-In with nonce: \(nonce.prefix(10))...")
            
            // Create and configure authorization controller
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            let coordinator = AppleSignInCoordinator()
            coordinator.nonce = nonce
            authorizationController.delegate = coordinator
            authorizationController.presentationContextProvider = coordinator
            
            // Start the sign-in flow
            try await coordinator.signIn(controller: authorizationController)
            
            await MainActor.run {
                isLoading = false
            }
            
            print("✅ Apple Sign-In completed successfully")
            
        } catch {
            print("❌ Apple Sign-In failed: \(error)")
            
            // Enhanced error handling based on Apple documentation
            let errorMessage: String
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    errorMessage = "Sign-in was canceled"
                case .failed:
                    errorMessage = "Apple Sign-In failed. Please try again."
                case .invalidResponse:
                    errorMessage = "Invalid response from Apple. Please try again."
                case .notHandled:
                    errorMessage = "Apple Sign-In not handled. Please contact support."
                case .unknown:
                    errorMessage = "Unknown Apple Sign-In error. Please check your Apple ID settings and try again."
                @unknown default:
                    errorMessage = "Apple Sign-In encountered an unexpected error."
                }
            } else {
                errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
            }
            
            await MainActor.run {
                isLoading = false
                self.errorMessage = errorMessage
            }
        }
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        #if canImport(GoogleSignIn)
        do {
            // Get the client ID from Firebase configuration (as per Firebase documentation)
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw NSError(domain: "GoogleSignIn", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to get Firebase client ID from GoogleService-Info.plist"])
            }
            
            print("📧 Starting Google Sign-In with client ID: \(clientID.prefix(20))...")
            
            // Create Google Sign In configuration object (as per Firebase documentation)
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            // Get the presenting view controller
            guard let presentingViewController = await getTopViewController() else {
                throw NSError(domain: "GoogleSignIn", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to get presenting view controller"])
            }
            
            print("📧 Presenting Google Sign-In interface...")
            
            // Start the sign-in flow (as per Firebase documentation)
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
                GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                    if let error = error {
                        print("❌ Google Sign-In error: \(error)")
                        continuation.resume(throwing: error)
                    } else if let result = result {
                        print("✅ Google Sign-In successful")
                        continuation.resume(returning: result)
                    } else {
                        print("❌ Google Sign-In returned no result and no error")
                        continuation.resume(throwing: NSError(domain: "GoogleSignIn", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown error - no result returned"]))
                    }
                }
            }
            
            // Extract tokens (as per Firebase documentation)
            let user = result.user
            guard let idToken = user.idToken?.tokenString else {
                throw NSError(domain: "GoogleSignIn", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token from Google Sign-In result"])
            }
            
            let accessToken = user.accessToken.tokenString
            
            print("📧 Successfully extracted Google tokens")
            print("📧 User email: \(user.profile?.email ?? "Not provided")")
            print("📧 User name: \(user.profile?.name ?? "Not provided")")
            
            // Create Firebase credential (as per Firebase documentation)
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            print("🔥 Signing in to Firebase with Google credential...")
            
            // Sign in to Firebase (as per Firebase documentation)
            let authResult = try await Auth.auth().signIn(with: credential)
            
            print("✅ Firebase authentication successful")
            print("✅ User UID: \(authResult.user.uid)")
            print("✅ Display Name: \(authResult.user.displayName ?? "Not set")")
            
            await MainActor.run {
                isLoading = false
            }
            
        } catch {
            print("❌ Google Sign-In failed: \(error)")
            await MainActor.run {
                isLoading = false
                errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
            }
        }
        #else
        // GoogleSignIn SDK not available
        print("⚠️ GoogleSignIn SDK not available")
        await MainActor.run {
            isLoading = false
            errorMessage = "Google Sign-In requires the GoogleSignIn SDK. Please add it to your project using Swift Package Manager: https://github.com/google/GoogleSignIn-iOS"
        }
        #endif
    }
    
    // Helper function to get the top view controller
    @MainActor
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        var topController = window.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        isLoading = true
        
        do {
            try Auth.auth().signOut()
            
            await MainActor.run {
                user = nil
                isAuthenticated = false
                isLoading = false
                
                // Clear user preferences
                UserDefaults.standard.removeObject(forKey: "currentUser")
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Sign out failed: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createAppUser(from firebaseUser: User) async {
        let appUser = AppUser(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "No email",
            displayName: firebaseUser.displayName ?? "No name",
            photoURL: firebaseUser.photoURL?.absoluteString,
            provider: determineProvider(from: firebaseUser),
            createdAt: Date()
        )
        
        self.user = appUser
        self.isAuthenticated = true
        
        // Save user to UserDefaults
        if let encoded = try? JSONEncoder().encode(appUser) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
    
    private func determineProvider(from user: User) -> AppUser.AuthProvider {
        if let providerData = user.providerData.first {
            switch providerData.providerID {
            case "apple.com":
                return .apple
            case "google.com":
                return .google
            default:
                return .guest
            }
        }
        return .guest
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - Apple Sign In Coordinator

@MainActor
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var nonce: String?
    private var continuation: CheckedContinuation<Void, Error>?
    
    func signIn(controller: ASAuthorizationController) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            print("🍎 Performing Apple authorization requests...")
            controller.performRequests()
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            print("⚠️ Warning: Using fallback window for Apple Sign-In presentation")
            return UIWindow()
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("🍎 Apple authorization completed successfully")
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("❌ Invalid credential type received")
            continuation?.resume(throwing: NSError(domain: "AppleSignIn", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"]))
            return
        }
        
        guard let nonce = nonce else {
            print("❌ Missing nonce - invalid state")
            continuation?.resume(throwing: NSError(domain: "AppleSignIn", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid state: A login callback was received, but no login request was sent."]))
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("❌ Unable to fetch Apple ID token")
            continuation?.resume(throwing: NSError(domain: "AppleSignIn", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"]))
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("❌ Unable to serialize token string from data")
            continuation?.resume(throwing: NSError(domain: "AppleSignIn", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string from data"]))
            return
        }
        
        print("🍎 Successfully extracted Apple ID token")
        print("🍎 User ID: \(appleIDCredential.user)")
        print("🍎 Email: \(appleIDCredential.email ?? "Not provided")")
        print("🍎 Full Name: \(appleIDCredential.fullName?.formatted() ?? "Not provided")")
        
        Task {
            do {
                // Create Firebase credential from Apple ID token
                let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                              rawNonce: nonce,
                                                              fullName: appleIDCredential.fullName)
                
                print("🔥 Signing in to Firebase with Apple credential...")
                let authResult = try await Auth.auth().signIn(with: credential)
                
                print("✅ Firebase authentication successful")
                print("✅ User UID: \(authResult.user.uid)")
                print("✅ Display Name: \(authResult.user.displayName ?? "Not set")")
                
                continuation?.resume()
            } catch {
                print("❌ Firebase authentication failed: \(error)")
                continuation?.resume(throwing: error)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple authorization failed with error: \(error)")
        
        if let authError = error as? ASAuthorizationError {
            print("❌ ASAuthorizationError code: \(authError.code.rawValue)")
            print("❌ ASAuthorizationError description: \(authError.localizedDescription)")
        }
        
        continuation?.resume(throwing: error)
    }
}
