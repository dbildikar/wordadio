import SwiftUI
import UIKit

/// Manages social sharing functionality
class ShareManager {
    static let shared = ShareManager()
    
    private let appStoreURL = "https://apps.apple.com/app/wordadio/id6740663405" // Update with real ID after launch
    
    private init() {}
    
    // MARK: - Share Level Completion
    
    /// Share level completion achievement
    func shareLevelComplete(level: Int, wordsFound: Int, bonusWords: Int, stars: Int) {
        let starEmoji = String(repeating: "⭐", count: stars)
        
        var message = "🎉 I just completed Level \(level) in WordAdio!\n\n"
        message += "\(starEmoji)\n"
        message += "📝 \(wordsFound) words found\n"
        if bonusWords > 0 {
            message += "✨ \(bonusWords) bonus words\n"
        }
        message += "\nCan you beat my score?\n\n"
        message += appStoreURL
        
        share(text: message)
        
        // Track analytics
        AnalyticsManager.shared.logShare(type: "level_complete", level: level)
    }
    
    // MARK: - Share Word Discovery
    
    /// Share a discovered word
    func shareWord(_ word: String, isBonus: Bool) {
        let wordType = isBonus ? "bonus word" : "word"
        
        var message = "📝 I found the \(word.count)-letter \(wordType) \"\(word)\" in WordAdio!\n\n"
        if word.count == 6 {
            message += "🎯 That's the full 6-letter word!\n\n"
        }
        message += "Try this addictive word puzzle game:\n"
        message += appStoreURL
        
        share(text: message)
        
        // Track analytics
        AnalyticsManager.shared.logShare(type: "word", level: nil)
    }
    
    // MARK: - Share High Level Milestone
    
    /// Share reaching a milestone level
    func shareMilestone(level: Int) {
        var message = "🏆 I've reached Level \(level) in WordAdio!\n\n"
        message += "This word puzzle game is seriously addictive. "
        message += "Think you can catch up?\n\n"
        message += appStoreURL
        
        share(text: message)
        
        // Track analytics
        AnalyticsManager.shared.logShare(type: "milestone", level: level)
    }
    
    // MARK: - Private
    
    private func share(text: String) {
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        // Exclude some activities that don't make sense
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .print,
            .saveToCameraRoll
        ]
        
        // Present the share sheet
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                // Handle iPad popover
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = rootVC.view
                    popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                rootVC.present(activityVC, animated: true)
            }
        }
    }
}
