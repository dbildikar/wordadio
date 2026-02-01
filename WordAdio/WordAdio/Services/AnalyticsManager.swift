import Foundation
import FirebaseAnalytics

/// Manages Firebase Analytics event tracking
class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - Game Events
    
    /// Track when a level starts
    func logLevelStart(levelNumber: Int) {
        Analytics.logEvent(AnalyticsEventLevelStart, parameters: [
            AnalyticsParameterLevelName: "Level \(levelNumber)",
            AnalyticsParameterLevel: levelNumber
        ])
    }
    
    /// Track when a level is completed
    func logLevelComplete(levelNumber: Int, wordsFound: Int, bonusWords: Int, coinsEarned: Int, hintsUsed: Int) {
        Analytics.logEvent(AnalyticsEventLevelEnd, parameters: [
            AnalyticsParameterLevelName: "Level \(levelNumber)",
            AnalyticsParameterLevel: levelNumber,
            AnalyticsParameterSuccess: true,
            "words_found": wordsFound,
            "bonus_words": bonusWords,
            "coins_earned": coinsEarned,
            "hints_used": hintsUsed
        ])
    }
    
    /// Track when a word is found
    func logWordFound(word: String, wordLength: Int, isBonus: Bool) {
        Analytics.logEvent("word_found", parameters: [
            "word_length": wordLength,
            "is_bonus": isBonus,
            "is_six_letter": wordLength == 6
        ])
    }
    
    /// Track hint usage
    func logHintUsed(paidWithCoins: Bool, coinsSpent: Int) {
        Analytics.logEvent("hint_used", parameters: [
            "paid_with_coins": paidWithCoins,
            "coins_spent": coinsSpent
        ])
    }
    
    /// Track when user waits for free hint
    func logFreeHintWait() {
        Analytics.logEvent("free_hint_wait", parameters: nil)
    }
    
    /// Track shuffle action
    func logShuffle() {
        Analytics.logEvent("shuffle_letters", parameters: nil)
    }
    
    // MARK: - Settings Events
    
    /// Track settings opened
    func logSettingsOpened() {
        Analytics.logEvent("settings_opened", parameters: nil)
    }
    
    /// Track music toggle
    func logMusicToggled(enabled: Bool) {
        Analytics.logEvent("music_toggled", parameters: [
            "enabled": enabled
        ])
    }
    
    /// Track sound effects toggle
    func logSoundEffectsToggled(enabled: Bool) {
        Analytics.logEvent("sound_effects_toggled", parameters: [
            "enabled": enabled
        ])
    }
    
    /// Track haptics toggle
    func logHapticsToggled(enabled: Bool) {
        Analytics.logEvent("haptics_toggled", parameters: [
            "enabled": enabled
        ])
    }
    
    // MARK: - Engagement Events
    
    /// Track bonus words sheet opened
    func logBonusWordsViewed(count: Int) {
        Analytics.logEvent("bonus_words_viewed", parameters: [
            "bonus_word_count": count
        ])
    }
    
    /// Track word definition viewed
    func logWordDefinitionViewed(word: String) {
        Analytics.logEvent("word_definition_viewed", parameters: [
            "word_length": word.count
        ])
    }
    
    // MARK: - Social Events
    
    /// Track when user shares content
    func logShare(type: String, level: Int?) {
        var params: [String: Any] = ["share_type": type]
        if let level = level {
            params["level"] = level
        }
        Analytics.logEvent(AnalyticsEventShare, parameters: params)
    }
    
    // MARK: - User Properties
    
    /// Set user's current level as a user property
    func setUserLevel(_ level: Int) {
        Analytics.setUserProperty("\(level)", forName: "current_level")
    }
    
    /// Set user's total coins as a user property
    func setUserCoins(_ coins: Int) {
        let coinBracket: String
        switch coins {
        case 0..<25: coinBracket = "0-24"
        case 25..<50: coinBracket = "25-49"
        case 50..<100: coinBracket = "50-99"
        case 100..<250: coinBracket = "100-249"
        default: coinBracket = "250+"
        }
        Analytics.setUserProperty(coinBracket, forName: "coin_bracket")
    }
}
