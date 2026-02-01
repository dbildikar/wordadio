import Foundation
import SwiftUI

/// Manages achievement tracking and unlocking
class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published private(set) var achievements: [Achievement] = []
    @Published var newlyUnlockedAchievement: Achievement?
    
    // Stats tracking
    @Published private(set) var stats: PlayerStats
    
    struct PlayerStats: Codable {
        var levelsCompleted: Int = 0
        var totalWordsFound: Int = 0
        var bonusWordsFound: Int = 0
        var perfectLevels: Int = 0  // 3-star levels
        var totalCoinsEarned: Int = 0
    }
    
    private let statsKey = "playerStats"
    private let achievementsKey = "unlockedAchievements"
    
    private init() {
        // Load stats
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(PlayerStats.self, from: data) {
            stats = decoded
        } else {
            stats = PlayerStats()
        }
        
        // Load achievements with unlock status
        loadAchievements()
    }
    
    private func loadAchievements() {
        var loadedAchievements = Achievements.all
        
        // Load unlocked status
        if let data = UserDefaults.standard.data(forKey: achievementsKey),
           let unlocked = try? JSONDecoder().decode([String: Date].self, from: data) {
            for i in loadedAchievements.indices {
                if let unlockedDate = unlocked[loadedAchievements[i].id] {
                    loadedAchievements[i].isUnlocked = true
                    loadedAchievements[i].unlockedDate = unlockedDate
                }
            }
        }
        
        achievements = loadedAchievements
    }
    
    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: statsKey)
        }
    }
    
    private func saveAchievements() {
        var unlocked: [String: Date] = [:]
        for achievement in achievements where achievement.isUnlocked {
            unlocked[achievement.id] = achievement.unlockedDate
        }
        if let encoded = try? JSONEncoder().encode(unlocked) {
            UserDefaults.standard.set(encoded, forKey: achievementsKey)
        }
    }
    
    // MARK: - Progress Tracking
    
    /// Call when a level is completed
    func recordLevelComplete(wordsFound: Int, bonusWords: Int, stars: Int, coinsEarned: Int) {
        stats.levelsCompleted += 1
        stats.totalWordsFound += wordsFound
        stats.bonusWordsFound += bonusWords
        stats.totalCoinsEarned += coinsEarned
        
        if stars == 3 {
            stats.perfectLevels += 1
        }
        
        saveStats()
        checkAchievements()
    }
    
    /// Call when a word is found (for real-time tracking)
    func recordWordFound(isBonus: Bool) {
        stats.totalWordsFound += 1
        if isBonus {
            stats.bonusWordsFound += 1
        }
        saveStats()
        // Don't check achievements on every word - too frequent
    }
    
    // MARK: - Achievement Checking
    
    private func checkAchievements() {
        var newUnlock: Achievement?
        
        for i in achievements.indices {
            guard !achievements[i].isUnlocked else { continue }
            
            let shouldUnlock: Bool
            switch achievements[i].id {
            // Level achievements
            case "level_5": shouldUnlock = stats.levelsCompleted >= 5
            case "level_10": shouldUnlock = stats.levelsCompleted >= 10
            case "level_25": shouldUnlock = stats.levelsCompleted >= 25
            case "level_50": shouldUnlock = stats.levelsCompleted >= 50
            case "level_100": shouldUnlock = stats.levelsCompleted >= 100
                
            // Word achievements
            case "words_25": shouldUnlock = stats.totalWordsFound >= 25
            case "words_100": shouldUnlock = stats.totalWordsFound >= 100
            case "words_250": shouldUnlock = stats.totalWordsFound >= 250
            case "words_500": shouldUnlock = stats.totalWordsFound >= 500
            case "words_1000": shouldUnlock = stats.totalWordsFound >= 1000
                
            // Bonus achievements
            case "bonus_10": shouldUnlock = stats.bonusWordsFound >= 10
            case "bonus_50": shouldUnlock = stats.bonusWordsFound >= 50
            case "bonus_100": shouldUnlock = stats.bonusWordsFound >= 100
                
            // Mastery achievements
            case "perfect_3": shouldUnlock = stats.perfectLevels >= 3
            case "perfect_10": shouldUnlock = stats.perfectLevels >= 10
            case "coins_100": shouldUnlock = stats.totalCoinsEarned >= 100
            case "coins_500": shouldUnlock = stats.totalCoinsEarned >= 500
                
            default: shouldUnlock = false
            }
            
            if shouldUnlock {
                achievements[i].isUnlocked = true
                achievements[i].unlockedDate = Date()
                newUnlock = achievements[i]
                
                // Log to analytics
                AnalyticsManager.shared.logAchievementUnlocked(achievementId: achievements[i].id)
            }
        }
        
        saveAchievements()
        
        // Show the most recently unlocked achievement
        if let unlock = newUnlock {
            DispatchQueue.main.async {
                self.newlyUnlockedAchievement = unlock
            }
        }
    }
    
    // MARK: - Helpers
    
    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    var totalCount: Int {
        achievements.count
    }
    
    func progress(for achievement: Achievement) -> Double {
        let current: Int
        switch achievement.id {
        case let id where id.starts(with: "level_"): current = stats.levelsCompleted
        case let id where id.starts(with: "words_"): current = stats.totalWordsFound
        case let id where id.starts(with: "bonus_"): current = stats.bonusWordsFound
        case let id where id.starts(with: "perfect_"): current = stats.perfectLevels
        case let id where id.starts(with: "coins_"): current = stats.totalCoinsEarned
        default: current = 0
        }
        return min(1.0, Double(current) / Double(achievement.requirement))
    }
    
    func currentValue(for achievement: Achievement) -> Int {
        switch achievement.id {
        case let id where id.starts(with: "level_"): return stats.levelsCompleted
        case let id where id.starts(with: "words_"): return stats.totalWordsFound
        case let id where id.starts(with: "bonus_"): return stats.bonusWordsFound
        case let id where id.starts(with: "perfect_"): return stats.perfectLevels
        case let id where id.starts(with: "coins_"): return stats.totalCoinsEarned
        default: return 0
        }
    }
}
