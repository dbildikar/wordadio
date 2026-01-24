import Foundation

/// Represents game progress and statistics
struct GameProgress: Codable {
    var currentLevel: Int
    var coins: Int
    var totalBonusWords: Int
    var longestWord: String
    var consecutiveCompletedLevels: Int
    var completedLevels: Set<Int>
    var lastPlayedDate: Date
    
    // Current level state (persists found words)
    var currentLevelFoundWords: Set<String>
    var currentLevelBonusWords: Set<String>
    var currentLevelCoinsEarned: Int
    var currentLevelHintsUsed: Int

    init() {
        self.currentLevel = 1
        self.coins = CoinRules.startingCoins  // Start with 50 coins
        self.totalBonusWords = 0
        self.longestWord = ""
        self.consecutiveCompletedLevels = 0
        self.completedLevels = []
        self.lastPlayedDate = Date()
        self.currentLevelFoundWords = []
        self.currentLevelBonusWords = []
        self.currentLevelCoinsEarned = 0
        self.currentLevelHintsUsed = 0
    }
    
    /// Clear current level state (called when moving to next level)
    mutating func clearCurrentLevelState() {
        currentLevelFoundWords = []
        currentLevelBonusWords = []
        currentLevelCoinsEarned = 0
        currentLevelHintsUsed = 0
    }
}
