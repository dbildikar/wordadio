import Foundation
import GameKit
import SwiftUI

/// Manages Game Center authentication and leaderboards
class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()
    
    @Published var isAuthenticated = false
    @Published var showLeaderboard = false
    
    // Leaderboard IDs - must match App Store Connect configuration
    static let leaderboardLevels = "com.bluefeatherai.wordadio.levels"
    static let leaderboardWords = "com.bluefeatherai.wordadio.words"
    
    private override init() {
        super.init()
    }
    
    // MARK: - Authentication
    
    /// Authenticate with Game Center
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                if error != nil {
                    self?.isAuthenticated = false
                    return
                }
                
                // If there's a view controller, we need to present it for sign-in
                if let vc = viewController {
                    self?.presentAuthViewController(vc)
                    return
                }
                
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
            }
        }
    }
    
    /// Present the authentication view controller
    private func presentAuthViewController(_ viewController: UIViewController) {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                topVC.present(viewController, animated: true)
            }
        }
    }
    
    /// Check current auth status
    func checkAuthStatus() {
        isAuthenticated = GKLocalPlayer.local.isAuthenticated
    }
    
    // MARK: - Leaderboard Submission
    
    /// Submit level score to leaderboard
    func submitLevelScore(_ level: Int) {
        guard isAuthenticated else { return }
        
        GKLeaderboard.submitScore(
            level,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.leaderboardLevels]
        ) { error in
            if let error = error {
                print("Failed to submit level score: \(error.localizedDescription)")
            } else {
                print("Level score submitted: \(level)")
                AnalyticsManager.shared.logLeaderboardSubmit(score: level)
            }
        }
    }
    
    /// Submit total words score to leaderboard
    func submitWordsScore(_ words: Int) {
        guard isAuthenticated else { return }
        
        GKLeaderboard.submitScore(
            words,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.leaderboardWords]
        ) { error in
            if let error = error {
                print("Failed to submit words score: \(error.localizedDescription)")
            } else {
                print("Words score submitted: \(words)")
            }
        }
    }
    
    // MARK: - Show Leaderboard
    
    /// Present the Game Center leaderboard UI
    func presentLeaderboard() {
        guard isAuthenticated else {
            openGameCenterSettings()
            return
        }
        
        showLeaderboard = true
    }
    
    /// Open Game Center settings so user can sign in
    func openGameCenterSettings() {
        // Open the Game Center section in Settings
        if let url = URL(string: "App-prefs:GAMECENTER") {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "App-prefs:root=GAMECENTER") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - SwiftUI Leaderboard View

struct GameCenterLeaderboardView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let viewController = GKGameCenterViewController(leaderboardID: GameCenterManager.leaderboardLevels, playerScope: .global, timeScope: .allTime)
        viewController.gameCenterDelegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let parent: GameCenterLeaderboardView
        
        init(_ parent: GameCenterLeaderboardView) {
            self.parent = parent
        }
        
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            parent.dismiss()
        }
    }
}
