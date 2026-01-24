import Foundation

// MARK: - Coin Economy

/// Rules for earning and spending coins in the game
enum CoinRules {
    // Starting coins for new players
    static let startingCoins = 50
    
    // Earning coins
    static let coinsPerLetter = 1                    // 1 coin per letter in puzzle words
    static let bonusWordMultiplier = 2               // 2x coins for bonus words
    static let levelCompletionBonus = 25             // +25 for completing level
    static let noHintsBonus = 15                     // +15 if no hints used
    static let sixLetterWordBonus = 10               // +10 bonus for 6-letter words
    static let streakBonusPerLevel = 5               // +5 per streak level
    
    // Spending coins
    static let hintCost = 10                         // 10 coins per hint
    
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
