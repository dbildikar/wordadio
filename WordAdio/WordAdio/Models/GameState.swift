import Foundation

/// Represents the current game state
struct GameState {
    var puzzle: Puzzle
    var wordSlots: [WordSlot]
    var foundWords: Set<String>
    var bonusWords: Set<String>
    var currentWord: String
    var coinsEarnedThisLevel: Int
    var isLevelComplete: Bool

    init(puzzle: Puzzle) {
        self.puzzle = puzzle
        self.wordSlots = puzzle.wordSlots.map { $0.toWordSlot() }
        self.foundWords = []
        self.bonusWords = []
        self.currentWord = ""
        self.coinsEarnedThisLevel = 0
        self.isLevelComplete = false
    }
    
    /// Initialize with restored state from persistence
    init(puzzle: Puzzle, foundWords: Set<String>, bonusWords: Set<String>, coinsEarned: Int, hintsUsed: Int) {
        self.puzzle = puzzle
        self.wordSlots = puzzle.wordSlots.map { $0.toWordSlot() }
        self.foundWords = foundWords
        self.bonusWords = bonusWords
        self.currentWord = ""
        self.coinsEarnedThisLevel = coinsEarned
        self.isLevelComplete = false
        
        // Restore filled letters for found words
        for word in foundWords {
            for i in 0..<wordSlots.count {
                if wordSlots[i].word == word.uppercased() {
                    for (index, char) in word.uppercased().enumerated() {
                        wordSlots[i].filledLetters[index] = char
                        // Fill intersecting slots
                        let position = wordSlots[i].position(at: index)
                        for j in 0..<wordSlots.count where j != i {
                            if let otherIndex = wordSlots[j].index(at: position) {
                                wordSlots[j].filledLetters[otherIndex] = char
                            }
                        }
                    }
                    break
                }
            }
        }
        
        // Check if level is already complete
        isLevelComplete = wordSlots.allSatisfy { $0.isFilled }
    }

    /// Check if all word slots are filled
    mutating func checkCompletion() {
        isLevelComplete = wordSlots.allSatisfy { $0.isFilled }
    }

    /// Fill a letter at a specific position and propagate to intersecting slots
    mutating func fillLetter(slotIndex: Int, letterIndex: Int, character: Character) {
        wordSlots[slotIndex].filledLetters[letterIndex] = character

        // Get the grid position for this letter
        let position = wordSlots[slotIndex].position(at: letterIndex)

        // Fill the same position in all other intersecting slots
        for j in 0..<wordSlots.count where j != slotIndex {
            if let otherIndex = wordSlots[j].index(at: position) {
                wordSlots[j].filledLetters[otherIndex] = character
            }
        }
    }

    /// Fill a word into the matching slot
    mutating func fillWord(_ word: String) -> Bool {
        for i in 0..<wordSlots.count {
            if wordSlots[i].word == word.uppercased() && !wordSlots[i].isFilled {
                for (index, char) in word.uppercased().enumerated() {
                    fillLetter(slotIndex: i, letterIndex: index, character: char)
                }
                foundWords.insert(word.uppercased())
                return true
            }
        }
        return false
    }
    
    /// Fill a word and return the positions that were filled (for animation)
    mutating func fillWordAndGetPositions(_ word: String) -> Set<GridPosition>? {
        for i in 0..<wordSlots.count {
            if wordSlots[i].word == word.uppercased() && !wordSlots[i].isFilled {
                var filledPositions: Set<GridPosition> = []
                for (index, char) in word.uppercased().enumerated() {
                    let position = wordSlots[i].position(at: index)
                    filledPositions.insert(position)
                    fillLetter(slotIndex: i, letterIndex: index, character: char)
                }
                foundWords.insert(word.uppercased())
                return filledPositions
            }
        }
        return nil
    }

    /// Get the character at a specific grid position
    func characterAt(position: GridPosition) -> Character? {
        for slot in wordSlots {
            if let index = slot.index(at: position),
               let char = slot.filledLetters[index] {
                return char
            }
        }
        return nil
    }
}
