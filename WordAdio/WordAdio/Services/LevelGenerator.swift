import Foundation

/// Service for generating puzzle levels
/// Algorithm:
/// 1. Select a base 6-letter word
/// 2. Find intersecting words that share letters with the base word
/// 3. Place words on a grid in crossword style
/// 4. Verify puzzle is solvable
/// 5. Extract unique letters for the wheel
class LevelGenerator {
    // Constants
    private static let MAX_WORD_LENGTH = 6
    private static let MIN_WORD_LENGTH = 3
    private static let BASE_WORD_LENGTH = 6
    private static let MAX_WHEEL_LETTERS = 6
    private static let MIN_WHEEL_LETTERS = 5
    private static let MIN_WORD_COUNT = 6
    private static let MAX_WORD_COUNT = 10
    
    private let dictionary = DictionaryService.shared
    private var randomGenerator: SeededRandomGenerator?

    init(seed: UInt64? = nil) {
        if let seed = seed {
            self.randomGenerator = SeededRandomGenerator(seed: seed)
        }
    }

    /// Generate a puzzle for a specific level
    /// - Parameter levelNumber: The level number (affects difficulty)
    /// - Returns: A complete, solvable puzzle
    func generatePuzzle(levelNumber: Int) -> Puzzle? {
        // Generate procedural crossword puzzle for all levels
        return generateCrosswordPuzzle(levelNumber: levelNumber)
    }

    /// Generate a crossword-style puzzle procedurally
    private func generateCrosswordPuzzle(levelNumber: Int) -> Puzzle? {
        // Try multiple base words until we get a valid puzzle
        let maxAttempts = 50
        var attempts = 0
        var usedWords: Set<String> = []
        
        while attempts < maxAttempts {
            attempts += 1
            
            // Get a random base word (try different ones if previous attempts failed)
            let baseWord = dictionary.getRandomBaseWord(excluding: usedWords, seed: UInt64(levelNumber * 1000 + attempts))
            guard baseWord.count == Self.BASE_WORD_LENGTH else {
                continue
            }
            usedWords.insert(baseWord)
            
            if let puzzle = tryGeneratePuzzleWithBaseWord(baseWord: baseWord, levelNumber: levelNumber) {
                return puzzle
            }
        }
        
        return nil
    }
    
    /// Try to generate a puzzle with a specific base word
    private func tryGeneratePuzzleWithBaseWord(baseWord: String, levelNumber: Int) -> Puzzle? {
        // Base word must be exactly BASE_WORD_LENGTH letters
        guard baseWord.count == Self.BASE_WORD_LENGTH else {
            return nil
        }
        
        let baseChars = Array(baseWord)

        // Target word count: between MIN_WORD_COUNT and MAX_WORD_COUNT
        // Vary by level but stay within bounds
        let targetWordCount = min(Self.MIN_WORD_COUNT + (levelNumber % (Self.MAX_WORD_COUNT - Self.MIN_WORD_COUNT + 1)), Self.MAX_WORD_COUNT)

        var slots: [WordSlot] = []
        var grid: [GridPosition: Character] = [:]

        // Place the base word horizontally at (2, 0)
        let baseSlot = WordSlot(
            word: baseWord,
            direction: .horizontal,
            startRow: 2,
            startCol: 0
        )
        slots.append(baseSlot)

        // Mark base word positions in grid
        for (i, char) in baseChars.enumerated() {
            grid[GridPosition(row: 2, col: i)] = char
        }

        // Try to add vertical words intersecting each letter of the base word
        var rng = SeededRandomGenerator(seed: UInt64(levelNumber * 1000))

        // Track word lengths we have to ensure variety
        var lengthCounts: [Int: Int] = [3: 0, 4: 0, 5: 0, 6: 1] // Base word is 6 letters
        
        // Helper to get prioritized lengths (prefer lengths we have fewer of)
        func prioritizedLengths() -> [Int] {
            let lengths = [3, 4, 5, 6]
            return lengths.sorted { lengthCounts[$0, default: 0] < lengthCounts[$1, default: 0] }
        }
        
        // First pass: try to add vertical words from base word
        for (i, baseChar) in baseChars.enumerated() {
            if slots.count >= targetWordCount { break }

            // Try lengths in priority order (prefer lengths we don't have yet)
            for length in prioritizedLengths() {
                if slots.count >= targetWordCount { break }
                if let verticalWord = findIntersectingWord(
                    containing: baseChar,
                    length: length,
                    from: baseChars,
                    excluding: slots.map { $0.word },
                    grid: grid,
                    rng: &rng
                ) {
                    // Find where in the vertical word this character appears
                    if let charIndex = verticalWord.firstIndex(of: baseChar) {
                        let offset = verticalWord.distance(from: verticalWord.startIndex, to: charIndex)
                        let startRow = 2 - offset
                        let startCol = i

                        // Check if this position would conflict with existing words
                        if canPlaceWord(verticalWord, at: startRow, col: startCol, direction: .vertical, in: grid) {
                            let slot = WordSlot(
                                word: verticalWord,
                                direction: .vertical,
                                startRow: startRow,
                                startCol: startCol
                            )
                            slots.append(slot)
                            lengthCounts[verticalWord.count, default: 0] += 1

                            // Update grid
                            for (j, char) in verticalWord.enumerated() {
                                grid[GridPosition(row: startRow + j, col: startCol)] = char
                            }
                            break // Found a word, move to next base char
                        }
                    }
                }
            }
        }

        // Second pass: try to add horizontal words intersecting with vertical words
        var passCount = 0
        while slots.count < Self.MIN_WORD_COUNT && passCount < 5 {
            passCount += 1
            for vertSlot in slots where vertSlot.direction == .vertical {
                if slots.count >= targetWordCount { break }

                for (i, char) in vertSlot.word.enumerated() {
                    if slots.count >= targetWordCount { break }

                    let pos = GridPosition(row: vertSlot.startRow + i, col: vertSlot.startCol)

                    // Try lengths in priority order (prefer lengths we don't have yet)
                    for length in prioritizedLengths() {
                        if slots.count >= targetWordCount { break }
                        if let horizWord = findIntersectingWord(
                            containing: char,
                            length: length,
                            from: baseChars,
                            excluding: slots.map { $0.word },
                            grid: grid,
                            rng: &rng
                        ) {
                            if let charIndex = horizWord.firstIndex(of: char) {
                                let offset = horizWord.distance(from: horizWord.startIndex, to: charIndex)
                                let startRow = pos.row
                                let startCol = pos.col - offset

                                if canPlaceWord(horizWord, at: startRow, col: startCol, direction: .horizontal, in: grid) {
                                    let slot = WordSlot(
                                        word: horizWord,
                                        direction: .horizontal,
                                        startRow: startRow,
                                        startCol: startCol
                                    )
                                    slots.append(slot)
                                    lengthCounts[horizWord.count, default: 0] += 1

                                    // Update grid
                                    for (j, char) in horizWord.enumerated() {
                                        grid[GridPosition(row: startRow, col: startCol + j)] = char
                                    }
                                    break // Found a word, move to next position
                                }
                            }
                        }
                    }
                }
            }
        }

        // Normalize grid to start at (0,0)
        let (normalizedSlots, gridSize) = normalizeGrid(slots: slots)

        // For each word, count letter frequencies
        // The wheel needs the MAXIMUM count of each letter across all words
        // This way, any single word can be formed from the wheel
        var maxLetterCounts: [Character: Int] = [:]
        for slot in normalizedSlots {
            var wordLetterCounts: [Character: Int] = [:]
            for char in slot.word {
                wordLetterCounts[char, default: 0] += 1
            }
            // Take the maximum for each letter
            for (char, count) in wordLetterCounts {
                maxLetterCounts[char] = max(maxLetterCounts[char, default: 0], count)
            }
        }
        
        // Build wheel with the maximum frequency needed for each letter
        var wheelLetters: [Character] = []
        for (char, count) in maxLetterCounts {
            for _ in 0..<count {
                wheelLetters.append(char)
            }
        }
        
        // If we have fewer than MIN_WHEEL_LETTERS, add random letters
        while wheelLetters.count < Self.MIN_WHEEL_LETTERS {
            let randomLetter = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".randomElement()!
            if !wheelLetters.contains(randomLetter) {
                wheelLetters.append(randomLetter)
            }
        }
        
        // If we have more than MAX_WHEEL_LETTERS, this puzzle won't work
        if wheelLetters.count > Self.MAX_WHEEL_LETTERS {
            // This puzzle requires too many letters, reject it
            return nil
        }

        // Validate word count is within bounds
        guard normalizedSlots.count >= Self.MIN_WORD_COUNT && normalizedSlots.count <= Self.MAX_WORD_COUNT else {
            // Return nil to signal this base word didn't work, try another
            return nil
        }

        return Puzzle(
            levelNumber: levelNumber,
            baseWord: baseWord,
            wordSlots: normalizedSlots,
            wheelLetters: wheelLetters.shuffled(),
            gridSize: gridSize
        )
    }


    /// Check if a word can be placed at a position without conflicts
    private func canPlaceWord(_ word: String, at row: Int, col: Int, direction: WordSlot.Direction, in grid: [GridPosition: Character]) -> Bool {
        // Check that word doesn't extend adjacent to existing tiles in the same direction
        // This prevents creating visual "super words" that look longer than 6 letters
        if direction == .horizontal {
            // Check tile immediately before the word
            let beforePos = GridPosition(row: row, col: col - 1)
            if grid[beforePos] != nil {
                return false // Would create adjacent horizontal tiles
            }
            // Check tile immediately after the word
            let afterPos = GridPosition(row: row, col: col + word.count)
            if grid[afterPos] != nil {
                return false // Would create adjacent horizontal tiles
            }
        } else {
            // Check tile immediately above the word
            let beforePos = GridPosition(row: row - 1, col: col)
            if grid[beforePos] != nil {
                return false // Would create adjacent vertical tiles
            }
            // Check tile immediately below the word
            let afterPos = GridPosition(row: row + word.count, col: col)
            if grid[afterPos] != nil {
                return false // Would create adjacent vertical tiles
            }
        }
        
        for (i, char) in word.enumerated() {
            let pos = direction == .horizontal ?
                GridPosition(row: row, col: col + i) :
                GridPosition(row: row + i, col: col)

            // If position is occupied, character must match
            if let existingChar = grid[pos], existingChar != char {
                return false
            }

            // Check perpendicular positions to avoid creating invalid letter combinations
            let perpPositions = direction == .horizontal ?
                [GridPosition(row: row - 1, col: col + i), GridPosition(row: row + 1, col: col + i)] :
                [GridPosition(row: row + i, col: col - 1), GridPosition(row: row + i, col: col + 1)]

            // Only allow perpendicular connections at intersections
            for perpPos in perpPositions {
                if grid[perpPos] != nil && grid[pos] == nil {
                    return false
                }
            }
        }
        return true
    }

    /// Normalize grid positions to start at (0,0)
    private func normalizeGrid(slots: [WordSlot]) -> ([WordSlot], Puzzle.GridSize) {
        var minRow = Int.max
        var minCol = Int.max
        var maxRow = Int.min
        var maxCol = Int.min

        for slot in slots {
            for i in 0..<slot.word.count {
                let pos = slot.position(at: i)
                minRow = min(minRow, pos.row)
                minCol = min(minCol, pos.col)
                maxRow = max(maxRow, pos.row)
                maxCol = max(maxCol, pos.col)
            }
        }

        let offsetRow = -minRow
        let offsetCol = -minCol

        let normalizedSlots = slots.map { slot in
            WordSlot(
                word: slot.word,
                direction: slot.direction,
                startRow: slot.startRow + offsetRow,
                startCol: slot.startCol + offsetCol
            )
        }

        return (
            normalizedSlots,
            Puzzle.GridSize(rows: maxRow - minRow + 1, cols: maxCol - minCol + 1)
        )
    }

    /// Find a word that intersects with existing words at a specific character
    private func findIntersectingWord(
        containing char: Character,
        length: Int,
        from availableLetters: [Character],
        excluding: [String],
        grid: [GridPosition: Character],
        rng: inout SeededRandomGenerator
    ) -> String? {
        // Length must be within valid range
        guard length >= Self.MIN_WORD_LENGTH && length <= Self.MAX_WORD_LENGTH else {
            return nil
        }
        let wordsOfLength = dictionary.words(ofLength: length)

        // Shuffle with seeded RNG for deterministic results
        var shuffled: [String] = []
        var remaining = wordsOfLength
        while !remaining.isEmpty {
            let index = Int.random(in: 0..<remaining.count, using: &rng)
            shuffled.append(remaining[index])
            remaining.remove(at: index)
        }

        for word in shuffled {
            // Word must be exactly the requested length (which is guaranteed to be <= MAX_WORD_LENGTH)
            guard word.count == length else {
                continue
            }
            if word.contains(char) &&
               dictionary.canFormWord(word, from: availableLetters) &&
               !excluding.contains(word) {
                return word
            }
        }

        return nil
    }

    /// Validate that a puzzle is solvable
    func validatePuzzle(_ puzzle: Puzzle) -> Bool {
        // Base word must be exactly BASE_WORD_LENGTH
        guard puzzle.baseWord.count == Self.BASE_WORD_LENGTH else {
            return false
        }
        
        // Grid size must be reasonable (no dimension larger than 10 to prevent huge grids)
        let maxGridDimension = 10
        guard puzzle.gridSize.rows <= maxGridDimension && puzzle.gridSize.cols <= maxGridDimension else {
            return false
        }
        
        // Wheel letters must be within constraints
        guard puzzle.wheelLetters.count <= Self.MAX_WHEEL_LETTERS else {
            return false
        }
        guard puzzle.wheelLetters.count >= Self.MIN_WHEEL_LETTERS else {
            return false
        }
        
        // Word count must be within constraints
        guard puzzle.wordSlots.count >= Self.MIN_WORD_COUNT && puzzle.wordSlots.count <= Self.MAX_WORD_COUNT else {
            return false
        }
        
        // All words must be valid and within length constraints
        for slotData in puzzle.wordSlots {
            if slotData.word.count < Self.MIN_WORD_LENGTH || slotData.word.count > Self.MAX_WORD_LENGTH {
                return false
            }
            if !dictionary.isValidWord(slotData.word) {
                return false
            }
        }

        // Check for overlaps (words must share letters at intersections)
        var grid: [GridPosition: Character] = [:]

        for slotData in puzzle.wordSlots {
            let slot = slotData.toWordSlot()
            for i in 0..<slot.word.count {
                let pos = slot.position(at: i)
                let char = slot.word[slot.word.index(slot.word.startIndex, offsetBy: i)]

                if let existingChar = grid[pos] {
                    // Intersection must have the same character
                    if existingChar != char {
                        return false
                    }
                } else {
                    grid[pos] = char
                }
            }
        }

        // CRITICAL: Check that ALL words together can be formed from wheel letters
        // with the constraint that each letter can only be used once (accounting for intersections)
        // In a crossword, letters at intersections are shared, so we count unique positions
        
        // Count how many times each letter appears in the puzzle grid (each position counts once)
        var letterCounts: [Character: Int] = [:]
        for (_, char) in grid {
            letterCounts[char, default: 0] += 1
        }

        // Count how many times each letter is available in the wheel
        var wheelLetterCounts: [Character: Int] = [:]
        for char in puzzle.wheelLetters {
            wheelLetterCounts[char, default: 0] += 1
        }

        // Verify that for each letter, we have enough in the wheel
        for (char, neededCount) in letterCounts {
            let availableCount = wheelLetterCounts[char, default: 0]
            if availableCount < neededCount {
                return false
            }
        }

        // Also verify each word individually can be formed (this is a sanity check)
        for slotData in puzzle.wordSlots {
            if !dictionary.canFormWord(slotData.word, from: puzzle.wheelLetters) {
                return false
            }
        }

        return true
    }
}
