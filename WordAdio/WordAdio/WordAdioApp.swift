import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency
import StoreKit
import Firebase

@main
struct WordAdioApp: App {
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Initialize Google Mobile Ads SDK
        MobileAds.shared.start()
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .preferredColorScheme(.light)
        }
    }
}

// MARK: - App Tracking Transparency Manager

class ATTManager {
    static let shared = ATTManager()
    private init() {}
    
    /// Request App Tracking Transparency permission
    func requestTrackingPermission() {
        // Only request on iOS 14.5+
        if #available(iOS 14.5, *) {
            // Delay slightly to ensure app is fully loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    // Permission handled - ads will work regardless
                    // but may be less personalized if denied
                }
            }
        }
    }
}

// MARK: - Rate App Manager

class RateAppManager {
    static let shared = RateAppManager()
    private let levelsCompletedKey = "levelsCompletedForReview"
    private let hasRequestedReviewKey = "hasRequestedReview"
    
    private init() {}
    
    /// Record a level completion and potentially request a review
    func recordLevelCompletion() {
        let defaults = UserDefaults.standard
        var completedCount = defaults.integer(forKey: levelsCompletedKey)
        completedCount += 1
        defaults.set(completedCount, forKey: levelsCompletedKey)
        
        // Request review after 3, 10, and 25 levels
        let reviewMilestones = [3, 10, 25]
        if reviewMilestones.contains(completedCount) {
            requestReviewIfAppropriate()
        }
    }
    
    /// Request an app review if appropriate
    private func requestReviewIfAppropriate() {
        // Use the new API for iOS 16+
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
    }
}

// MARK: - Splash Screen

struct SplashScreenView: View {
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            // ContentView is always there
            ContentView()
            
            // Splash overlay
            if showSplash {
                GeometryReader { geo in
                    Image("Splash")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                    
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                            .padding(.bottom, geo.safeAreaInsets.bottom + 80)
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
    }
}
