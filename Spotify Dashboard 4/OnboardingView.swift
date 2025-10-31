//
//  OnboardingView.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    
    @State private var currentPage = 0
    @State private var animateIcons = false
    @State private var animateFeatures = false
    
    var body: some View {
        ZStack {
            // Enhanced background gradient with depth
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.1, blue: 0.3),
                        Color(red: 0.25, green: 0.15, blue: 0.4),
                        Color(red: 0.1, green: 0.05, blue: 0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Animated gradient overlay
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.2),
                        Color.blue.opacity(0.15),
                        Color.pink.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
            
            // Floating orbs for visual interest
            GeometryReader { geometry in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 60)
                    .offset(x: -50, y: -100)
                    .opacity(0.6)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.pink.opacity(0.3), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                    .blur(radius: 50)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 200)
                    .opacity(0.5)
            }
            .ignoresSafeArea()
            
            welcomePage
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                animateIcons = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animateFeatures = true
                }
            }
        }
    }
    
    // MARK: - Welcome Page
    
    var welcomePage: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)
                
                // Main Icon with animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 60
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 70, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.pink, Color.purple, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, value: animateIcons)
                        .shadow(color: Color.purple.opacity(0.5), radius: 15, x: 0, y: 5)
                }
                .scaleEffect(animateIcons ? 1.0 : 0.8)
                .opacity(animateFeatures ? 1.0 : 0)
                .padding(.bottom, 20)
                
                // Title with gradient
                Text("Music Story")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(white: 0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                    .padding(.bottom, 5)
                
                Text("Companion")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.bottom, 15)
                
                // Subtitle
                Text("Where stories meet music")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(Color(white: 0.75))
                    .padding(.bottom, 40)
                
                // Feature cards
                VStack(spacing: 16) {
                    FeatureCard(
                        icon: "text.book.closed.fill",
                        title: "Classic Literature",
                        description: "Dive into a world of timeless stories and literary masterpieces",
                        gradient: [Color.purple, Color.pink],
                        delay: 0.1
                    )
                    .offset(x: animateFeatures ? 0 : -50)
                    .opacity(animateFeatures ? 1 : 0)
                    
                    FeatureCard(
                        icon: "waveform.circle.fill",
                        title: "Adaptive Music",
                        description: "Dynamic soundtracks that match your story's mood",
                        gradient: [Color.blue, Color.cyan],
                        delay: 0.2
                    )
                    .offset(x: animateFeatures ? 0 : 50)
                    .opacity(animateFeatures ? 1 : 0)
                    
                    FeatureCard(
                        icon: "person.2.fill",
                        title: "Discover Authors",
                        description: "Explore authors and their literary works",
                        gradient: [Color.orange, Color.pink],
                        delay: 0.3
                    )
                    .offset(x: animateFeatures ? 0 : -50)
                    .opacity(animateFeatures ? 1 : 0)
                    
                    FeatureCard(
                        icon: "heart.text.square.fill",
                        title: "Mood Tracking",
                        description: "Track your emotional journey through stories",
                        gradient: [Color.purple, Color.blue],
                        delay: 0.4
                    )
                    .offset(x: animateFeatures ? 0 : 50)
                    .opacity(animateFeatures ? 1 : 0)
                    
                    FeatureCard(
                        icon: "brain.head.profile.fill",
                        title: "AI Powered Insights",
                        description: "Smart advice, summaries & insights powered by Apple AI",
                        gradient: [Color.indigo, Color.purple],
                        delay: 0.5
                    )
                    .offset(x: animateFeatures ? 0 : -50)
                    .opacity(animateFeatures ? 1 : 0)
                    
                    FeatureCard(
                        icon: "headphones.circle.fill",
                        title: "Podcasts",
                        description: "Listen to curated podcast content",
                        gradient: [Color.green, Color.blue],
                        delay: 0.6
                    )
                    .offset(x: animateFeatures ? 0 : 50)
                    .opacity(animateFeatures ? 1 : 0)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                
                // Get Started button with enhanced design
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        hasCompletedOnboarding = true
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Get Started")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .symbolEffect(.bounce, value: hasCompletedOnboarding)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        ZStack {
                            // Glow effect
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .blur(radius: 10)
                            
                            // Main gradient
                            LinearGradient(
                                colors: [Color.purple, Color.blue, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .cornerRadius(20)
                        }
                    )
                    .shadow(color: Color.purple.opacity(0.5), radius: 20, x: 0, y: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
                .scaleEffect(animateFeatures ? 1.0 : 0.9)
                .opacity(animateFeatures ? 1.0 : 0)
            }
        }
    }
    
    // MARK: - Helper Functions
    func savePreferences() {
        // Placeholder for future onboarding preferences
    }
}

// MARK: - Feature Card Component
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
    let delay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: gradient[0].opacity(0.4), radius: 10, x: 0, y: 5)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(white: 0.75))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [
                            gradient[0].opacity(0.3),
                            gradient[1].opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isVisible = true
                }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.8)
    }
}


