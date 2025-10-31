//
//  SpotifyAuthView.swift
//  Spotify Dashboard
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import SwiftUI
import SafariServices

struct SpotifyAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = SpotifyAuthManager()
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.green, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Connect to Spotify")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in to access your personal playlists and create custom reading soundtracks")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Benefits
                VStack(alignment: .leading, spacing: 12) {
                    Text("What you'll get:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    BenefitRow(icon: "music.note.list", text: "Access to your personal playlists")
                    BenefitRow(icon: "waveform", text: "Custom reading soundtracks")
                    BenefitRow(icon: "heart.fill", text: "Save your favorite reading music")
                    BenefitRow(icon: "person.circle", text: "Personalized recommendations")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Authentication Button
                VStack(spacing: 16) {
                    if isAuthenticating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Connecting to Spotify...")
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                    } else {
                        Button(action: {
                            authenticateWithSpotify()
                        }) {
                            HStack {
                                Image(systemName: "music.note")
                                Text("Sign in with Spotify")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                    
                    // Skip button
                    Button("Skip for now") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Spotify")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
    
    private func authenticateWithSpotify() {
        isAuthenticating = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.startAuthentication()
                await MainActor.run {
                    isAuthenticating = false
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    errorMessage = "Failed to authenticate: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

// MARK: - Spotify Authentication Manager

class SpotifyAuthManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    @Published var refreshToken: String?
    @Published var user: SpotifyUser?
    
    let clientId = SpotifyConfig.clientId
    private let clientSecret = SpotifyConfig.clientSecret
    private let redirectURI = SpotifyConfig.redirectURI
    
    private var safariViewController: SFSafariViewController?
    
    override init() {
        super.init()
        // Listen for Spotify callback notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSpotifyCallback(_:)),
            name: NSNotification.Name("SpotifyAuthCallback"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleSpotifyCallback(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let code = userInfo["code"] as? String else {
            print("❌ No authorization code in callback")
            return
        }
        
        Task {
            await handleAuthCallback(code: code)
        }
    }
    
    func startAuthentication() async throws {
        print("🎵 SpotifyAuthView: Starting authentication...")
        
        // URL encode the redirect URI
        let encodedRedirectURI = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURI
        
        let authURL = "https://accounts.spotify.com/authorize?client_id=\(clientId)&response_type=code&redirect_uri=\(encodedRedirectURI)&scope=user-read-private%20user-read-email%20playlist-read-private%20playlist-read-collaborative%20user-library-read"
        
        print("🎵 Auth URL: \(authURL)")
        
        guard let url = URL(string: authURL) else {
            print("❌ Invalid auth URL")
            throw NSError(domain: "SpotifyAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid auth URL"])
        }
        
        print("🎵 Presenting Safari view controller...")
        await MainActor.run {
            self.safariViewController = SFSafariViewController(url: url)
            self.safariViewController?.delegate = self
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                print("🎵 Found window, presenting Safari...")
                rootViewController.present(self.safariViewController!, animated: true)
            } else {
                print("❌ Could not find window to present Safari")
                // Try alternative approach
                if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
                   let rootVC = keyWindow.rootViewController {
                    rootVC.present(self.safariViewController!, animated: true)
                }
            }
        }
    }
    
    func handleAuthCallback(code: String) async {
        do {
            let tokenResponse = try await exchangeCodeForToken(code: code)
            
            await MainActor.run {
                self.accessToken = tokenResponse.accessToken
                self.refreshToken = tokenResponse.refreshToken
                self.isAuthenticated = true
                
                // Save tokens to UserDefaults
                UserDefaults.standard.set(tokenResponse.accessToken, forKey: "spotify_access_token")
                UserDefaults.standard.set(tokenResponse.refreshToken, forKey: "spotify_refresh_token")
                
                // Dismiss Safari view controller
                self.safariViewController?.dismiss(animated: true)
                self.safariViewController = nil
            }
            
            // Fetch user profile
            try await fetchUserProfile()
            
        } catch {
            print("❌ Auth callback error: \(error)")
        }
    }
    
    private func exchangeCodeForToken(code: String) async throws -> TokenResponse {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "\(clientId):\(clientSecret)"
        let credentialsBase64 = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(credentialsBase64)", forHTTPHeaderField: "Authorization")
        
        // URL encode the redirect URI for the body
        let encodedRedirectURI = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURI
        let body = "grant_type=authorization_code&code=\(code)&redirect_uri=\(encodedRedirectURI)"
        request.httpBody = body.data(using: .utf8)
        
        print("🎵 Token exchange request body: \(body)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SpotifyAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("🎵 Token exchange response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 400 {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Token exchange error: \(errorString)")
            throw NSError(domain: "SpotifyAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Bad request: \(errorString)"])
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Token exchange failed: \(errorString)")
            throw NSError(domain: "SpotifyAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Token exchange failed: \(errorString)"])
        }
        
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }
    
    private func fetchUserProfile() async throws {
        guard let accessToken = accessToken else { return }
        
        let url = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let user = try JSONDecoder().decode(SpotifyUser.self, from: data)
        
        await MainActor.run {
            self.user = user
        }
    }
}

// MARK: - SFSafariViewControllerDelegate
extension SpotifyAuthManager: SFSafariViewControllerDelegate {
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        // Handle initial load completion if needed
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        // Handle when user cancels or finishes authentication
        controller.dismiss(animated: true)
    }
}


