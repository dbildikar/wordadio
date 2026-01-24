import XCTest
@testable import WordAdio

/// Unit tests for core game functionality
final class WordAdioTests: XCTestCase {

    // MARK: - Dictionary Tests

    func testDictionaryLoading() {
        let dictionary = DictionaryService.shared

        // Test that dictionary has words
        XCTAssertTrue(dictionary.words(ofLength: 6).count > 0, "Dictionary should contain 6-letter words")
        XCTAssertTrue(dictionary.words(ofLength: 5).count > 0, "Dictionary should contain 5-letter words")
        XCTAssertTrue(dictionary.words(ofLength: 4).count > 0, "Dictionary should contain 4-letter words")
        XCTAssertTrue(dictionary.words(ofLength: 3).count > 0, "Dictionary should contain 3-letter words")
    }

    func testWordValidation() {
        let dictionary = DictionaryService.shared

        // Test valid words
        XCTAssertTrue(dictionary.isValidWord("SPRING"), "SPRING should be valid")
        XCTAssertTrue(dictionary.isValidWord("RING"), "RING should be valid")
        XCTAssertTrue(dictionary.isValidWord("PIN"), "PIN should be valid")

        // Test case insensitivity
        XCTAssertTrue(dictionary.isValidWord("spring"), "spring (lowercase) should be valid")
        XCTAssertTrue(dictionary.isValidWord("Spring"), "Spring (mixed case) should be valid")

        // Test invalid words
        XCTAssertFalse(dictionary.isValidWord("ZZZZZ"), "ZZZZZ should be invalid")
        XCTAssertFalse(dictionary.isValidWord("XQZ"), "XQZ should be invalid")
    }

    func testCanFormWord() {
        let dictionary = DictionaryService.shared
        let letters: [Character] = ["S", "P", "R", "I", "N", "G"]

        // Test words that can be formed
        XCTAssertTrue(dictionary.canFormWord("SPRING", from: letters), "Can form SPRING")
        XCTAssertTrue(dictionary.canFormWord("SPIN", from: letters), "Can form SPIN")
        XCTAssertTrue(dictionary.canFormWord("RING", from: letters), "Can form RING")
        XCTAssertTrue(dictionary.canFormWord("PIN", from: letters), "Can form PIN")

        // Test words that cannot be formed
        XCTAssertFalse(dictionary.canFormWord("TRAIN", from: letters), "Cannot form TRAIN")
        XCTAssertFalse(dictionary.canFormWord("BREAD", from: letters), "Cannot form BREAD")

        // Test letter reuse constraint
        XCTAssertFalse(dictionary.canFormWord("SINGING", from: letters), "Cannot form SINGING (would need multiple G's)")
    }

    func testFindWords() {
        let dictionary = DictionaryService.shared
        let letters: [Character] = ["S", "P", "R", "I", "N", "G"]

        let foundWords = dictionary.findWords(from: letters, minLength: 3)

        // Should find these words at minimum
        XCTAssertTrue(foundWords.contains("SPRING"), "Should find SPRING")
        XCTAssertTrue(foundWords.contains("SPIN"), "Should find SPIN")
        XCTAssertTrue(foundWords.contains("RING"), "Should find RING")
        XCTAssertTrue(foundWords.contains("GRIN"), "Should find GRIN")
        XCTAssertTrue(foundWords.contains("PIN"), "Should find PIN")
        XCTAssertTrue(foundWords.contains("SIN"), "Should find SIN")
        XCTAssertTrue(foundWords.contains("RIG"), "Should find RIG")

        // Should not find words that can't be formed
        XCTAssertFalse(foundWords.contains("TRAIN"), "Should not find TRAIN")
        XCTAssertFalse(foundWords.contains("BREAD"), "Should not find BREAD")
    }

    // MARK: - Puzzle Generation Tests

    func testPuzzleGeneration() {
        let generator = LevelGenerator()

        // Test generating first 5 predefined levels
        for level in 1...5 {
            let puzzle = generator.generatePuzzle(levelNumber: level)
            XCTAssertNotNil(puzzle, "Should generate puzzle for level \(level)")

            if let puzzle = puzzle {
                XCTAssertEqual(puzzle.levelNumber, level, "Puzzle should have correct level number")
                XCTAssertEqual(puzzle.baseWord.count, 6, "Base word should be 6 letters")
                XCTAssertTrue(puzzle.wordSlots.count > 1, "Should have multiple word slots")
                XCTAssertTrue(puzzle.wheelLetters.count >= 5, "Should have at least 5 wheel letters")
                XCTAssertTrue(puzzle.wheelLetters.count <= 7, "Should have at most 7 wheel letters")
            }
        }
    }

    func testPuzzleSolvability() {
        let generator = LevelGenerator()

        for level in 1...5 {
            guard let puzzle = generator.generatePuzzle(levelNumber: level) else {
                XCTFail("Failed to generate puzzle for level \(level)")
                continue
            }

            XCTAssertTrue(generator.validatePuzzle(puzzle), "Puzzle \(level) should be valid and solvable")

            // Verify all words can be formed from wheel letters
            let dictionary = DictionaryService.shared
            for slotData in puzzle.wordSlots {
                XCTAssertTrue(
                    dictionary.canFormWord(slotData.word, from: puzzle.wheelLetters),
                    "Word \(slotData.word) should be formable from wheel letters"
                )
            }
        }
    }

    func testDeterministicGeneration() {
        let seed: UInt64 = 12345

        let generator1 = LevelGenerator(seed: seed)
        let generator2 = LevelGenerator(seed: seed)

        let puzzle1 = generator1.generatePuzzle(levelNumber: 6)
        let puzzle2 = generator2.generatePuzzle(levelNumber: 6)

        XCTAssertNotNil(puzzle1, "First puzzle should generate")
        XCTAssertNotNil(puzzle2, "Second puzzle should generate")

        if let p1 = puzzle1, let p2 = puzzle2 {
            XCTAssertEqual(p1.baseWord, p2.baseWord, "Seeded puzzles should have same base word")
            XCTAssertEqual(p1.wheelLetters, p2.wheelLetters, "Seeded puzzles should have same wheel letters")
        }
    }

    // MARK: - Game Logic Tests

    func testWordSlotFilling() {
        let generator = LevelGenerator()
        guard let puzzle = generator.generatePuzzle(levelNumber: 1) else {
            XCTFail("Failed to generate puzzle")
            return
        }

        var gameState = GameState(puzzle: puzzle)

        // Get the first word slot
        let firstWord = gameState.wordSlots[0].word

        // Fill it
        let filled = gameState.fillWord(firstWord)

        XCTAssertTrue(filled, "Should successfully fill word")
        XCTAssertTrue(gameState.wordSlots[0].isFilled, "Word slot should be filled")
        XCTAssertTrue(gameState.foundWords.contains(firstWord), "Word should be in found words")

        // Try to fill again (should not work for same word)
        let filledAgain = gameState.fillWord(firstWord)
        XCTAssertFalse(filledAgain, "Should not fill same word twice")
    }

    func testLevelCompletion() {
        let generator = LevelGenerator()
        guard let puzzle = generator.generatePuzzle(levelNumber: 1) else {
            XCTFail("Failed to generate puzzle")
            return
        }

        var gameState = GameState(puzzle: puzzle)

        // Initially should not be complete
        gameState.checkCompletion()
        XCTAssertFalse(gameState.isLevelComplete, "Level should not be complete initially")

        // Fill all words
        for slot in gameState.wordSlots {
            _ = gameState.fillWord(slot.word)
        }

        // Check completion
        gameState.checkCompletion()
        XCTAssertTrue(gameState.isLevelComplete, "Level should be complete after filling all words")
    }

    func testScoring() {
        // Test regular word scoring
        let regularScore = ScoringRules.score(for: "SPRING", isBonus: false)
        XCTAssertEqual(regularScore, 60, "6-letter word should score 60 points (6 * 10)")

        // Test bonus word scoring
        let bonusScore = ScoringRules.score(for: "SPRING", isBonus: true)
        XCTAssertEqual(bonusScore, 120, "6-letter bonus word should score 120 points (6 * 10 * 2)")

        // Test level completion bonus
        XCTAssertEqual(ScoringRules.levelCompletionBonus, 100, "Level completion should award 100 points")
    }

    // MARK: - Wheel Input Tests

    @MainActor
    func testLetterSelection() {
        let viewModel = GameViewModel()

        // Select letters
        viewModel.selectLetter(at: 0)
        viewModel.selectLetter(at: 1)
        viewModel.selectLetter(at: 2)

        XCTAssertEqual(viewModel.selectedLetterIndices.count, 3, "Should have 3 selected letters")
        XCTAssertEqual(viewModel.currentWord.count, 3, "Current word should have 3 letters")

        // Try to select same letter again (should not work)
        viewModel.selectLetter(at: 0)
        XCTAssertEqual(viewModel.selectedLetterIndices.count, 3, "Should still have 3 selected letters")
    }

    @MainActor
    func testLetterDeselection() {
        let viewModel = GameViewModel()

        // Select letters
        viewModel.selectLetter(at: 0)
        viewModel.selectLetter(at: 1)
        viewModel.selectLetter(at: 2)

        // Deselect last letter
        viewModel.deselectLastLetter()

        XCTAssertEqual(viewModel.selectedLetterIndices.count, 2, "Should have 2 selected letters")
        XCTAssertEqual(viewModel.currentWord.count, 2, "Current word should have 2 letters")
    }

    @MainActor
    func testClearSelection() {
        let viewModel = GameViewModel()

        // Select letters
        viewModel.selectLetter(at: 0)
        viewModel.selectLetter(at: 1)
        viewModel.selectLetter(at: 2)

        // Clear
        viewModel.clearSelection()

        XCTAssertEqual(viewModel.selectedLetterIndices.count, 0, "Should have no selected letters")
        XCTAssertEqual(viewModel.currentWord.count, 0, "Current word should be empty")
        XCTAssertTrue(viewModel.wheelLetters.allSatisfy { !$0.isSelected }, "No letters should be selected")
    }

    // MARK: - Persistence Tests

    func testProgressSaving() {
        let persistence = PersistenceManager.shared

        // Clear any existing progress
        persistence.clearProgress()

        // Create test progress
        var progress = GameProgress()
        progress.currentLevel = 5
        progress.score = 1000
        progress.consecutiveCompletedLevels = 3

        // Save
        persistence.saveProgress(progress)

        // Load
        let loaded = persistence.loadProgress()

        XCTAssertEqual(loaded.currentLevel, 5, "Should load correct level")
        XCTAssertEqual(loaded.score, 1000, "Should load correct score")
        XCTAssertEqual(loaded.consecutiveCompletedLevels, 3, "Should load correct streak")

        // Clean up
        persistence.clearProgress()
    }

    func testLevelCompletionRecording() {
        let persistence = PersistenceManager.shared
        persistence.clearProgress()

        // Record completion
        persistence.recordLevelCompletion(
            levelNumber: 1,
            score: 200,
            bonusWords: 3,
            longestWord: "SPRING"
        )

        let progress = persistence.loadProgress()

        XCTAssertEqual(progress.currentLevel, 2, "Should advance to next level")
        XCTAssertEqual(progress.score, 200, "Should record score")
        XCTAssertEqual(progress.totalBonusWords, 3, "Should record bonus words")
        XCTAssertEqual(progress.longestWord, "SPRING", "Should record longest word")
        XCTAssertTrue(progress.completedLevels.contains(1), "Should mark level as completed")

        // Clean up
        persistence.clearProgress()
    }

    // MARK: - Grid Position Tests

    func testHorizontalWordPositions() {
        let slot = WordSlot(
            word: "SPRING",
            direction: .horizontal,
            startRow: 0,
            startCol: 0
        )

        XCTAssertEqual(slot.position(at: 0), GridPosition(row: 0, col: 0))
        XCTAssertEqual(slot.position(at: 1), GridPosition(row: 0, col: 1))
        XCTAssertEqual(slot.position(at: 5), GridPosition(row: 0, col: 5))
    }

    func testVerticalWordPositions() {
        let slot = WordSlot(
            word: "SPRING",
            direction: .vertical,
            startRow: 0,
            startCol: 0
        )

        XCTAssertEqual(slot.position(at: 0), GridPosition(row: 0, col: 0))
        XCTAssertEqual(slot.position(at: 1), GridPosition(row: 1, col: 0))
        XCTAssertEqual(slot.position(at: 5), GridPosition(row: 5, col: 0))
    }

    func testWordSlotContainsPosition() {
        let slot = WordSlot(
            word: "SPRING",
            direction: .horizontal,
            startRow: 2,
            startCol: 3
        )

        XCTAssertTrue(slot.contains(position: GridPosition(row: 2, col: 3)))
        XCTAssertTrue(slot.contains(position: GridPosition(row: 2, col: 4)))
        XCTAssertTrue(slot.contains(position: GridPosition(row: 2, col: 8)))

        XCTAssertFalse(slot.contains(position: GridPosition(row: 1, col: 3)))
        XCTAssertFalse(slot.contains(position: GridPosition(row: 2, col: 2)))
        XCTAssertFalse(slot.contains(position: GridPosition(row: 2, col: 9)))
    }
}
