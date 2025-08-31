//
//  RedditSettingsView.swift
//  Spotify Dashboard
//
//  Created by Ashfaq ahmed on 07/08/25.
//

import SwiftUI

struct RedditSettingsView: View {
    @State private var clientId = RedditConfig.clientId == "eRAgAAcJLwQCi3G4LACtZw" ?"": RedditConfig.clientId
    @State private var clientSecret = RedditConfig.clientSecret == "z6300YgsszDM-JhDmDeeXNdvWtvIOQ" ? "" : RedditConfig.clientSecret
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.9),
                        Color.purple.opacity(0.1),
                        Color.black.opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "gear")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                            
                            Text("Reddit API Settings")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Configure your Reddit API credentials to access authenticated endpoints with higher rate limits.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Setup Instructions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Setup Instructions:")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                InstructionStep(number: 1, text: "Go to https://www.reddit.com/prefs/apps")
                                InstructionStep(number: 2, text: "Click 'Create App' or 'Create Another App'")
                                InstructionStep(number: 3, text: "Select 'script' as app type")
                                InstructionStep(number: 4, text: "Copy your client ID and secret here")
                                InstructionStep(number: 5, text: "Save the settings to enable authentication")
                            }
                            .padding(.horizontal)
                        }
                        
                        // Credential Input Fields
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Client ID")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                TextField("Enter your Reddit Client ID", text: $clientId)
                                    .textFieldStyle(RedditTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Client Secret")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                SecureField("Enter your Reddit Client Secret", text: $clientSecret)
                                    .textFieldStyle(RedditTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                        }
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            Button("Save Settings") {
                                saveSettings()
                            }
                            .buttonStyle(RedditPrimaryButtonStyle())
                            .disabled(clientId.isEmpty || clientSecret.isEmpty)
                            
                            HStack(spacing: 20) {
                                Button("Test Connection") {
                                    testConnection()
                                }
                                .buttonStyle(RedditSecondaryButtonStyle())
                                
                                Button("Cancel") {
                                    dismiss()
                                }
                                .buttonStyle(RedditSecondaryButtonStyle())
                            }
                        }
                        .padding(.top)
                    }
                    .padding(.top)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Settings Saved", isPresented: $showingAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveSettings() {
//         In a real app, you'd save these to UserDefaults or Keychain
//         UserDefaults.standard.set(clientId, forKey: "reddit_client_id")
//         UserDefaults.standard.set(clientSecret, forKey: "reddit_client_secret")
        
        alertMessage = "Settings saved successfully!\n\nNote: Restart the app for changes to take effect."
        showingAlert = true
    }
    
    private func testConnection() {
        alertMessage = "To test the connection, please:\n1. Save your settings first\n2. Go to the Social tab\n3. Check if authentication shows 'Connected!'"
        showingAlert = true
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.green))
                .padding(.top, 2)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
        }
    }
}

struct RedditTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
            .padding(.horizontal)
    }
}

struct RedditPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.green, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .padding(.horizontal)
    }
}

struct RedditSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    RedditSettingsView()
}
