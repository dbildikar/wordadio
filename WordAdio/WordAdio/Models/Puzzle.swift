import Foundation

// MARK: - Core Puzzle Models

/// Represents a single letter in the puzzle
struct Letter: Identifiable, Equatable, Hashable {
    let id = UUID()
    let character: Character
    var isRevealed: Bool = false

    init(character: Character, isRevealed: Bool = false) {
        self.character = character
        self.isRevealed = isRevealed
    }
}

/// Represents a word slot in the crossword puzzle
struct WordSlot: Identifiable, Equatable {
    let id: UUID
    let word: String
    let direction: Direction
    let startRow: Int
    let startCol: Int
    var filledLetters: [Int: Character] = [:]
    
    init(id: UUID = UUID(), word: String, direction: Direction, startRow: Int, startCol: Int, filledLetters: [Int: Character] = [:]) {
        self.id = id
        self.word = word
        self.direction = direction
        self.startRow = startRow
        self.startCol = startCol
        self.filledLetters = filledLetters
    }

    enum Direction: String, Codable {
        case horizontal
        case vertical
    }

    var isFilled: Bool {
        filledLetters.count == word.count
    }

    var length: Int {
        word.count
    }

    /// Get the position for a specific letter index in this word
    func position(at index: Int) -> GridPosition {
        switch direction {
        case .horizontal:
            return GridPosition(row: startRow, col: startCol + index)
        case .vertical:
            return GridPosition(row: startRow + index, col: startCol)
        }
    }

    /// Check if this word slot contains a specific grid position
    func contains(position: GridPosition) -> Bool {
        for i in 0..<word.count {
            if self.position(at: i) == position {
                return true
            }
        }
        return false
    }

    /// Get the letter index at a specific position
    func index(at position: GridPosition) -> Int? {
        for i in 0..<word.count {
            if self.position(at: i) == position {
                return i
            }
        }
        return nil
    }
}

/// Represents a position on the grid
struct GridPosition: Hashable, Equatable {
    let row: Int
    let col: Int
}

/// Represents a complete puzzle level
struct Puzzle: Codable, Identifiable {
    let id: UUID
    let levelNumber: Int
    let baseWord: String
    let wordSlots: [WordSlotData]
    let wheelLetters: [Character]
    let gridSize: GridSize

    struct WordSlotData: Codable, Identifiable {
        let id: UUID
        let word: String
        let direction: String
        let startRow: Int
        let startCol: Int

        func toWordSlot() -> WordSlot {
            WordSlot(
                id: id,
                word: word,
                direction: direction == "horizontal" ? .horizontal : .vertical,
                startRow: startRow,
                startCol: startCol
            )
        }
    }

    struct GridSize: Codable {
        let rows: Int
        let cols: Int
    }

    enum CodingKeys: String, CodingKey {
        case id, levelNumber, baseWord, wordSlots, wheelLettersString, gridSize
    }

    init(id: UUID = UUID(), levelNumber: Int, baseWord: String, wordSlots: [WordSlot], wheelLetters: [Character], gridSize: GridSize) {
        self.id = id
        self.levelNumber = levelNumber
        self.baseWord = baseWord
        self.wordSlots = wordSlots.map { slot in
            WordSlotData(
                id: slot.id,
                word: slot.word,
                direction: slot.direction.rawValue,
                startRow: slot.startRow,
                startCol: slot.startCol
            )
        }
        self.wheelLetters = wheelLetters
        self.gridSize = gridSize
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        levelNumber = try container.decode(Int.self, forKey: .levelNumber)
        baseWord = try container.decode(String.self, forKey: .baseWord)
        wordSlots = try container.decode([WordSlotData].self, forKey: .wordSlots)
        let lettersString = try container.decode(String.self, forKey: .wheelLettersString)
        wheelLetters = Array(lettersString)
        gridSize = try container.decode(GridSize.self, forKey: .gridSize)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(levelNumber, forKey: .levelNumber)
        try container.encode(baseWord, forKey: .baseWord)
        try container.encode(wordSlots, forKey: .wordSlots)
        let lettersString = String(wheelLetters)
        try container.encode(lettersString, forKey: .wheelLettersString)
        try container.encode(gridSize, forKey: .gridSize)
    }
}
