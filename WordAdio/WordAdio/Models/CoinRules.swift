import Foundation

// MARK: - Coin Economy

/// Rules for earning coins in the game
enum CoinRules {
    // Starting coins for new players
    static let startingCoins = 25
    
    // Earning coins - ONLY for 6-letter words
    static let sixLetterWordReward = 10              // 10 coins for finding the 6-letter word
    static let levelCompletionBonus = 5              // +5 for completing level
    static let noHintsBonus = 3                      // +3 if no hints used
    
    // Hints are now FREE but time-gated (1 minute)
    static let hintUnlockSeconds: TimeInterval = 60  // 1 minute to unlock a free hint
    
    /// Calculate coins earned for finding a word
    /// Only 6-letter words earn coins now
    static func coins(for word: String, isBonus: Bool) -> Int {
        // Only 6-letter words earn coins
        if word.count == 6 {
            return sixLetterWordReward
        }
        return 0
    }
    
    /// Calculate total completion bonus
    static func completionBonus(hintsUsed: Int) -> Int {
        var bonus = levelCompletionBonus
        if hintsUsed == 0 {
            bonus += noHintsBonus
        }
        return bonus
    }
}
