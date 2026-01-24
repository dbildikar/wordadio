import Foundation

/// Manages local persistence of game progress and settings
class PersistenceManager {
    static let shared = PersistenceManager()

    private let progressKey = "gameProgress"
    private let defaults = UserDefaults.standard

    private init() {}

    /// Save game progress
    func saveProgress(_ progress: GameProgress) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(progress)
            defaults.set(data, forKey: progressKey)
        } catch {
            // Silently fail on save error
        }
    }

    /// Load game progress
    func loadProgress() -> GameProgress {
        guard let data = defaults.data(forKey: progressKey) else {
            return GameProgress()
        }

        do {
            let decoder = JSONDecoder()
            let progress = try decoder.decode(GameProgress.self, from: data)
            return progress
        } catch {
            return GameProgress()
        }
    }

    /// Clear all saved data
    func clearProgress() {
        defaults.removeObject(forKey: progressKey)
    }

    /// Update progress with level completion
    func recordLevelCompletion(
        levelNumber: Int,
        coinsEarned: Int,
        bonusWords: Int,
        longestWord: String,
        hintsUsed: Int = 0
    ) {
        var progress = loadProgress()

        // Coins are already added in GameViewModel.completeLevel()
        // Just track statistics here
        progress.totalBonusWords += bonusWords
        progress.completedLevels.insert(levelNumber)

        if longestWord.count > progress.longestWord.count {
            progress.longestWord = longestWord
        }

        // Update streak: only continues if level completed with 1 or fewer hints
        if hintsUsed <= 1 {
            progress.consecutiveCompletedLevels += 1
        } else {
            // Too many hints used, reset streak
            progress.consecutiveCompletedLevels = 0
        }
        
        progress.currentLevel = levelNumber + 1
        progress.lastPlayedDate = Date()

        saveProgress(progress)
    }
}
