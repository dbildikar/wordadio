import Foundation

// MARK: - Coin Economy

/// Rules for earning and spending coins in the game
enum CoinRules {
    // Starting coins for new players
    static let startingCoins = 25
    
    // Earning coins
    static let coinsPerLetter = 1                    // 1 coin per letter in puzzle words
    static let bonusWordMultiplier = 1               // 1x coins for bonus words (same as regular)
    static let levelCompletionBonus = 10             // +10 for completing level
    static let noHintsBonus = 5                      // +5 if no hints used
    static let sixLetterWordBonus = 3                // +3 bonus for 6-letter words
    static let streakBonusPerLevel = 2               // +2 per streak level
    
    // Spending coins
    static let hintCost = 15                         // 15 coins per hint
    
    /// Calculate coins earned for finding a word
    static func coins(for word: String, isBonus: Bool) -> Int {
        var coins = word.count * coinsPerLetter
        if isBonus {
            coins *= bonusWordMultiplier
        }
        // 6-letter word bonus
        if word.count == 6 {
            coins += sixLetterWordBonus
        }
        return coins
    }
    
    /// Calculate streak bonus coins
    static func streakBonus(streak: Int) -> Int {
        return streak * streakBonusPerLevel
    }
    
    /// Calculate total completion bonus (includes no-hints and streak)
    static func completionBonus(hintsUsed: Int, streak: Int) -> Int {
        var bonus = levelCompletionBonus
        if hintsUsed == 0 {
            bonus += noHintsBonus
        }
        bonus += streakBonus(streak: streak)
        return bonus
    }
}
