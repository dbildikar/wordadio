import Foundation

/// Represents an achievement/badge that can be earned
struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let requirement: Int
    let category: Category
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    
    enum Category: String, Codable, CaseIterable {
        case levels = "Levels"
        case words = "Words"
        case bonus = "Bonus"
        case mastery = "Mastery"
    }
}

/// All available achievements in the game
enum Achievements {
    static let all: [Achievement] = [
        // Level achievements
        Achievement(id: "level_5", name: "Getting Started", description: "Complete 5 levels", icon: "star.fill", requirement: 5, category: .levels),
        Achievement(id: "level_10", name: "Word Explorer", description: "Complete 10 levels", icon: "star.circle.fill", requirement: 10, category: .levels),
        Achievement(id: "level_25", name: "Puzzle Pro", description: "Complete 25 levels", icon: "sparkles", requirement: 25, category: .levels),
        Achievement(id: "level_50", name: "Word Master", description: "Complete 50 levels", icon: "crown.fill", requirement: 50, category: .levels),
        Achievement(id: "level_100", name: "Legendary", description: "Complete 100 levels", icon: "trophy.fill", requirement: 100, category: .levels),
        
        // Words found achievements
        Achievement(id: "words_25", name: "Wordsmith", description: "Find 25 words", icon: "textformat", requirement: 25, category: .words),
        Achievement(id: "words_100", name: "Vocabulary Builder", description: "Find 100 words", icon: "text.book.closed.fill", requirement: 100, category: .words),
        Achievement(id: "words_250", name: "Lexicon Expert", description: "Find 250 words", icon: "books.vertical.fill", requirement: 250, category: .words),
        Achievement(id: "words_500", name: "Walking Dictionary", description: "Find 500 words", icon: "character.book.closed.fill", requirement: 500, category: .words),
        Achievement(id: "words_1000", name: "Word Wizard", description: "Find 1,000 words", icon: "wand.and.stars", requirement: 1000, category: .words),
        
        // Bonus word achievements
        Achievement(id: "bonus_10", name: "Bonus Hunter", description: "Find 10 bonus words", icon: "gift.fill", requirement: 10, category: .bonus),
        Achievement(id: "bonus_50", name: "Treasure Seeker", description: "Find 50 bonus words", icon: "sparkle", requirement: 50, category: .bonus),
        Achievement(id: "bonus_100", name: "Hidden Gem Finder", description: "Find 100 bonus words", icon: "diamond.fill", requirement: 100, category: .bonus),
        
        // Mastery achievements
        Achievement(id: "perfect_3", name: "Triple Star", description: "Get 3 stars on 3 levels", icon: "star.leadinghalf.filled", requirement: 3, category: .mastery),
        Achievement(id: "perfect_10", name: "Perfectionist", description: "Get 3 stars on 10 levels", icon: "star.square.fill", requirement: 10, category: .mastery),
        Achievement(id: "coins_100", name: "Coin Collector", description: "Earn 100 coins", icon: "bitcoinsign.circle.fill", requirement: 100, category: .mastery),
        Achievement(id: "coins_500", name: "Rich Wordsmith", description: "Earn 500 coins", icon: "banknote.fill", requirement: 500, category: .mastery),
    ]
}
