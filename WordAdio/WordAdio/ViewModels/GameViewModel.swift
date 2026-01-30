import Foundation
import SwiftUI
import Combine

/// Main view model for game logic and state management
/// Follows MVVM architecture pattern
@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var gameState: GameState
    @Published var wheelLetters: [WheelLetter] = []
    @Published var currentWord: String = ""
    @Published var selectedLetterIndices: [Int] = []
    @Published var message: String = ""
    @Published var messageType: MessageType = .info
    @Published var progress: GameProgress
    @Published var showingMessage: Bool = false
    @Published var showingLevelComplete: Bool = false
    @Published var levelCompleteStats: LevelCompleteStats?
    @Published var developerSettings = DeveloperSettings()
    @Published var hintsUsedThisLevel: Int = 0
    
    // Hint system - pay with coins OR wait for free hint
    @Published var freeHintAvailable: Bool = false
    @Published var secondsUntilFreeHint: Int = 60
    private var hintTimer: Timer?
    private var lastActivityTime: Date = Date()
    
    /// Total coins available (bank + current level earnings)
    var totalAvailableCoins: Int {
        progress.coins + gameState.coinsEarnedThisLevel
    }
    
    /// Whether user can afford a paid hint
    var canAffordHint: Bool {
        totalAvailableCoins >= CoinRules.hintCost
    }
    
    // Animation triggers
    @Published var showShuffleAnimation: Bool = false
    @Published var showInvalidShake: Bool = false
    @Published var lastFilledPositions: Set<GridPosition> = []
    @Published var showCoinsAnimation: Bool = false
    @Published var lastCoinsEarned: Int = 0
    @Published var coinsAnimationColor: Color = .yellow
    
    struct LevelCompleteStats {
        let levelNumber: Int
        let wordsFound: Int
        let bonusWords: Int
        let coinsEarned: Int
        let completionBonus: Int
        let streak: Int
        let hintsUsed: Int
        
        var totalCoins: Int {
            coinsEarned + completionBonus
        }
        
        /// Calculate star rating: 1 base + 1 for bonus words + 1 for no hints
        var starCount: Int {
            var stars = 1 // Base star for completing
            if bonusWords > 0 { stars += 1 }
            if hintsUsed == 0 { stars += 1 }
            return stars
        }
    }

    // MARK: - Private Properties

    private let dictionary = DictionaryService.shared
    private let levelGenerator: LevelGenerator
    private let persistence = PersistenceManager.shared
    private let soundManager = SoundManager.shared
    private let haptics = HapticManager.shared
    private let adManager = AdManager.shared

    // MARK: - Initialization

    init(seed: UInt64? = nil) {
        // Load progress first
        let loadedProgress = PersistenceManager.shared.loadProgress()
        self.progress = loadedProgress
        self.levelGenerator = LevelGenerator(seed: seed)

        // Generate initial puzzle using temporary variable
        let tempLevelGenerator = LevelGenerator(seed: seed)
        let initialPuzzle: Puzzle
        
        // Try to generate puzzle for current level
        if let puzzle = tempLevelGenerator.generatePuzzle(levelNumber: loadedProgress.currentLevel) {
            initialPuzzle = puzzle
        } else {
            // Try level 1 as fallback
            if let fallbackPuzzle = tempLevelGenerator.generatePuzzle(levelNumber: 1) {
                initialPuzzle = fallbackPuzzle
            } else {
                // Last resort: try a few more levels
                var foundPuzzle: Puzzle? = nil
                for level in 1...10 {
                    if let puzzle = tempLevelGenerator.generatePuzzle(levelNumber: level) {
                        foundPuzzle = puzzle
                        break
                    }
                }
                
                // If still no puzzle, create a minimal fallback puzzle
                if let puzzle = foundPuzzle {
                    initialPuzzle = puzzle
                } else {
                    // Create emergency fallback puzzle
                    initialPuzzle = Self.createFallbackPuzzle()
                }
            }
        }
        
        // Restore game state with any previously found words
        if !initialPuzzle.wordSlots.isEmpty && 
           initialPuzzle.levelNumber == loadedProgress.currentLevel && 
           (!loadedProgress.currentLevelFoundWords.isEmpty || !loadedProgress.currentLevelBonusWords.isEmpty) {
            self.gameState = GameState(
                puzzle: initialPuzzle,
                foundWords: loadedProgress.currentLevelFoundWords,
                bonusWords: loadedProgress.currentLevelBonusWords,
                coinsEarned: loadedProgress.currentLevelCoinsEarned,
                hintsUsed: loadedProgress.currentLevelHintsUsed
            )
            self.hintsUsedThisLevel = loadedProgress.currentLevelHintsUsed
        } else {
            self.gameState = GameState(puzzle: initialPuzzle)
        }
        self.wheelLetters = initialPuzzle.wheelLetters.map { WheelLetter(character: $0) }
        
        // Start hint timer
        startHintTimer()
    }
    
    deinit {
        hintTimer?.invalidate()
    }
    
    /// Create a minimal fallback puzzle when generation fails
    private static func createFallbackPuzzle() -> Puzzle {
        let fallbackSlots = [
            WordSlot(word: "SPRING", direction: .horizontal, startRow: 0, startCol: 0),
            WordSlot(word: "RING", direction: .vertical, startRow: 0, startCol: 2),
            WordSlot(word: "SPIN", direction: .vertical, startRow: 0, startCol: 0),
            WordSlot(word: "GRIP", direction: .horizontal, startRow: 2, startCol: 1),
            WordSlot(word: "PINS", direction: .vertical, startRow: 0, startCol: 4),
            WordSlot(word: "RIGS", direction: .horizontal, startRow: 3, startCol: 0)
        ]
        return Puzzle(
            levelNumber: 1,
            baseWord: "SPRING",
            wordSlots: fallbackSlots,
            wheelLetters: Array("SPRING"),
            gridSize: Puzzle.GridSize(rows: 6, cols: 6)
        )
    }
    
    // MARK: - Hint Timer
    
    private func startHintTimer() {
        lastActivityTime = Date()
        freeHintAvailable = false
        secondsUntilFreeHint = Int(CoinRules.freeHintWaitSeconds)
        
        hintTimer?.invalidate()
        hintTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateHintTimer()
            }
        }
    }
    
    private func updateHintTimer() {
        let elapsed = Date().timeIntervalSince(lastActivityTime)
        let remaining = CoinRules.freeHintWaitSeconds - elapsed
        
        if remaining <= 0 {
            freeHintAvailable = true
            secondsUntilFreeHint = 0
        } else {
            freeHintAvailable = false
            secondsUntilFreeHint = Int(remaining)
        }
    }
    
    /// Reset the hint timer (called when user finds a word)
    private func resetHintTimer() {
        lastActivityTime = Date()
        freeHintAvailable = false
        secondsUntilFreeHint = Int(CoinRules.freeHintWaitSeconds)
    }

    // MARK: - Game Actions

    @Published var showConfetti: Bool = false
    @Published var lastBonusWord: String = ""
    
    /// Submit the current word
    func submitWord() {
        let word = currentWord.uppercased()

        guard word.count >= 3 else {
            soundManager.playErrorSound()
            haptics.error()
            triggerInvalidShake()
            showMessage("Word must be at least 3 letters", type: .error)
            clearSelection()
            return
        }

        guard dictionary.isValidWord(word) else {
            soundManager.playErrorSound()
            haptics.error()
            triggerInvalidShake()
            showMessage("Not a valid word", type: .error)
            clearSelection()
            return
        }

        guard !gameState.foundWords.contains(word) && !gameState.bonusWords.contains(word) else {
            soundManager.playDuplicateSound()
            haptics.warning()
            triggerInvalidShake()
            showMessage("Already found", type: .error)
            clearSelection()
            return
        }

        // Check if it's a puzzle word
        if let filledPositions = gameState.fillWordAndGetPositions(word) {
            soundManager.playSuccessSound()
            haptics.success()
            
            // Only 6-letter words earn coins
            let coins = CoinRules.coins(for: word, isBonus: false)
            if coins > 0 {
                soundManager.playPointsSound()
                gameState.coinsEarnedThisLevel += coins
                triggerCoinsAnimation(coins: coins, color: .yellow)
            }
            
            // Trigger animations
            lastFilledPositions = filledPositions
            
            // Trigger confetti for 6-letter words!
            if word.count == 6 {
                soundManager.playConfettiSound()
                showConfetti = true
            }
            
            // Reset hint timer on activity
            resetHintTimer()
            
            // Save progress
            saveCurrentLevelState()

            // Check for level completion
            gameState.checkCompletion()
            if gameState.isLevelComplete {
                completeLevel()
            }
        } else {
            // It's a bonus word
            soundManager.playBonusWordSound()
            haptics.success()
            
            gameState.bonusWords.insert(word)
            
            // Only 6-letter bonus words earn coins
            let coins = CoinRules.coins(for: word, isBonus: true)
            if coins > 0 {
                soundManager.playPointsSound()
                gameState.coinsEarnedThisLevel += coins
                triggerCoinsAnimation(coins: coins, color: .orange)
            }
            
            showMessage("Bonus!", type: .success)
            
            // Reset hint timer on activity
            resetHintTimer()
            
            // Save progress
            saveCurrentLevelState()
        }

        clearSelection()
    }

    /// Select a letter from the wheel
    func selectLetter(at index: Int) {
        guard index >= 0 && index < wheelLetters.count else { return }

        // Prevent using the same position twice
        guard !selectedLetterIndices.contains(index) else {
            return
        }

        // Play ascending musical note and haptic
        soundManager.playLetterSelectSound(index: selectedLetterIndices.count)
        haptics.lightTap()

        selectedLetterIndices.append(index)
        wheelLetters[index].isSelected = true
        currentWord += String(wheelLetters[index].character)
    }

    /// Deselect the last letter
    func deselectLastLetter() {
        guard !selectedLetterIndices.isEmpty else { return }

        soundManager.playDeselectSound()
        
        let lastIndex = selectedLetterIndices.removeLast()
        wheelLetters[lastIndex].isSelected = false

        if !currentWord.isEmpty {
            currentWord.removeLast()
        }
    }

    /// Clear all selections
    func clearSelection() {
        selectedLetterIndices.removeAll()
        for i in 0..<wheelLetters.count {
            wheelLetters[i].isSelected = false
        }
        currentWord = ""
        soundManager.resetNoteSequence()
    }

    /// Shuffle the wheel letters
    func shuffleWheel() {
        soundManager.playShuffleSound()
        haptics.mediumTap()
        
        // Trigger shuffle animation
        showShuffleAnimation = true
        
        let chars = wheelLetters.map { $0.character }
        let shuffled = chars.shuffled()
        wheelLetters = shuffled.map { WheelLetter(character: $0) }
        clearSelection()
        
        // Reset animation after delay
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            showShuffleAnimation = false
        }
    }

    /// Complete the current level
    private func completeLevel() {
        let bonusCount = gameState.bonusWords.count
        let allWords = gameState.foundWords.union(gameState.bonusWords)
        let longestWord = allWords.max(by: { $0.count < $1.count }) ?? ""

        // Calculate completion bonus
        let completionBonus = CoinRules.completionBonus(hintsUsed: hintsUsedThisLevel)
        
        // Total coins earned (added to progress in recordLevelCompletion)
        let totalCoinsEarned = gameState.coinsEarnedThisLevel + completionBonus

        // Play level complete sound and haptic
        soundManager.playLevelCompleteSound()
        haptics.heavyTap()
        
        // Stop hint timer
        hintTimer?.invalidate()
        
        // Refresh the ad
        adManager.refreshAd()
        
        // Track for rate app prompt
        RateAppManager.shared.recordLevelCompletion()

        // Record in persistence and clear current level state
        persistence.recordLevelCompletion(
            levelNumber: gameState.puzzle.levelNumber,
            coinsEarned: totalCoinsEarned,
            bonusWords: bonusCount,
            longestWord: longestWord,
            hintsUsed: hintsUsedThisLevel
        )

        // Update progress and clear current level state (level is complete)
        progress = persistence.loadProgress()
        progress.clearCurrentLevelState()
        persistence.saveProgress(progress)

        // Show level complete animation
        levelCompleteStats = LevelCompleteStats(
            levelNumber: gameState.puzzle.levelNumber,
            wordsFound: gameState.foundWords.count,
            bonusWords: bonusCount,
            coinsEarned: gameState.coinsEarnedThisLevel,
            completionBonus: completionBonus,
            streak: progress.consecutiveCompletedLevels,
            hintsUsed: hintsUsedThisLevel
        )
        showingLevelComplete = true
    }
    
    /// Continue to next level (called from level complete overlay)
    func continueToNextLevel() {
        showingLevelComplete = false
        levelCompleteStats = nil
        hintsUsedThisLevel = 0
        loadNextLevel()
        
        // Restart hint timer for new level
        startHintTimer()
    }

    /// Load the next level
    func loadNextLevel() {
        let nextLevel = progress.currentLevel + 1
        
        if let nextPuzzle = levelGenerator.generatePuzzle(levelNumber: nextLevel), !nextPuzzle.wordSlots.isEmpty {
            gameState = GameState(puzzle: nextPuzzle)
            wheelLetters = nextPuzzle.wheelLetters.map { WheelLetter(character: $0) }
            clearSelection()
            
            // Update progress to new level and clear current level state
            progress.currentLevel = nextLevel
            progress.clearCurrentLevelState()
            persistence.saveProgress(progress)
            
            showMessage("Level \(nextPuzzle.levelNumber)", type: .info)
        } else {
            showMessage("Failed to generate puzzle", type: .error)
        }
    }

    /// Reset the current level
    func resetLevel() {
        let currentLevel = gameState.puzzle.levelNumber
        hintsUsedThisLevel = 0
        
        if let puzzle = levelGenerator.generatePuzzle(levelNumber: currentLevel), !puzzle.wordSlots.isEmpty {
            gameState = GameState(puzzle: puzzle)
            wheelLetters = puzzle.wheelLetters.map { WheelLetter(character: $0) }
            clearSelection()
            
            // Clear current level state
            progress.clearCurrentLevelState()
            persistence.saveProgress(progress)
            
            // Restart hint timer
            startHintTimer()
            
            showMessage("Level reset", type: .info)
        } else {
            showMessage("Failed to reset puzzle", type: .error)
        }
    }

    /// Use a hint to reveal one letter
    /// - If user has coins: pay coins for instant hint
    /// - If user has no coins: must wait for free hint timer
    func useHint() {
        let usingPaidHint = canAffordHint
        
        // If no coins, check if free hint is available
        if !usingPaidHint && !freeHintAvailable {
            soundManager.playErrorSound()
            haptics.error()
            showMessage("Hint in \(secondsUntilFreeHint)s (or \(CoinRules.hintCost) coins)", type: .error)
            return
        }
        
        // Find the first word with empty letters
        for i in 0..<gameState.wordSlots.count {
            let slot = gameState.wordSlots[i]

            // Find first empty position in this word
            for letterIndex in 0..<slot.word.count {
                if slot.filledLetters[letterIndex] == nil {
                    // Deduct coins if using paid hint
                    if usingPaidHint {
                        if gameState.coinsEarnedThisLevel >= CoinRules.hintCost {
                            gameState.coinsEarnedThisLevel -= CoinRules.hintCost
                        } else {
                            let remainingCost = CoinRules.hintCost - gameState.coinsEarnedThisLevel
                            gameState.coinsEarnedThisLevel = 0
                            progress.coins -= remainingCost
                        }
                        persistence.saveProgress(progress)
                    }
                    
                    // Fill this one letter and propagate to intersecting slots
                    let charIndex = slot.word.index(slot.word.startIndex, offsetBy: letterIndex)
                    let character = slot.word[charIndex]

                    // Play hint sound and haptic
                    soundManager.playHintSound()
                    soundManager.playTileFillSound()
                    haptics.lightTap()
                    
                    // Get the position for animation
                    let position = slot.position(at: letterIndex)
                    lastFilledPositions = [position]
                    
                    gameState.fillLetter(slotIndex: i, letterIndex: letterIndex, character: character)
                    
                    // Track hint usage
                    hintsUsedThisLevel += 1
                    
                    // Reset hint timer (user must wait another minute for next free hint)
                    resetHintTimer()
                    
                    // Save progress after hint
                    saveCurrentLevelState()

                    showMessage("Hint: \(character)", type: .info)

                    // Check for level completion
                    gameState.checkCompletion()
                    if gameState.isLevelComplete {
                        // Mark word as found when complete
                        gameState.foundWords.insert(slot.word)
                        completeLevel()
                    }

                    return
                }
            }
        }

        // All letters are filled
        showMessage("All letters revealed!", type: .success)
    }

    // MARK: - Developer Tools

    /// Reveal the solution
    func revealSolution() {
        developerSettings.showSolution.toggle()
    }

    /// Auto-solve the current level
    func autoSolve() {
        for slot in gameState.wordSlots {
            _ = gameState.fillWord(slot.word)
        }
        gameState.checkCompletion()
        if gameState.isLevelComplete {
            completeLevel()
        }
    }

    /// Get all possible words for developer view
    func getPossibleWords() -> [String] {
        return dictionary.findWords(from: gameState.puzzle.wheelLetters, minLength: 3)
    }

    // MARK: - Helper Methods
    
    /// Save current level state to persistence
    private func saveCurrentLevelState() {
        progress.currentLevelFoundWords = gameState.foundWords
        progress.currentLevelBonusWords = gameState.bonusWords
        progress.currentLevelCoinsEarned = gameState.coinsEarnedThisLevel
        progress.currentLevelHintsUsed = hintsUsedThisLevel
        persistence.saveProgress(progress)
    }
    
    /// Trigger invalid word shake animation
    private func triggerInvalidShake() {
        showInvalidShake = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            showInvalidShake = false
        }
    }
    
    /// Trigger coins animation
    private func triggerCoinsAnimation(coins: Int, color: Color) {
        lastCoinsEarned = coins
        coinsAnimationColor = color
        showCoinsAnimation = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            showCoinsAnimation = false
        }
    }
    
    /// Clear filled positions animation after delay
    func clearFilledPositionsAnimation() {
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            lastFilledPositions = []
        }
    }

    private func showMessage(_ text: String, type: MessageType) {
        message = text
        messageType = type
        showingMessage = true

        // Auto-hide after 2 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showingMessage = false
        }
    }

    /// Check if a position in the grid should be visible
    func isPositionInPuzzle(row: Int, col: Int) -> Bool {
        let position = GridPosition(row: row, col: col)
        return gameState.wordSlots.contains { $0.contains(position: position) }
    }

    /// Get the character at a grid position
    func characterAt(row: Int, col: Int) -> Character? {
        let position = GridPosition(row: row, col: col)
        return gameState.characterAt(position: position)
    }

    /// Get the solution character at a grid position (for developer mode)
    func solutionCharacterAt(row: Int, col: Int) -> Character? {
        guard developerSettings.showSolution else { return nil }
        let position = GridPosition(row: row, col: col)

        for slot in gameState.wordSlots {
            if let index = slot.index(at: position) {
                let charIndex = slot.word.index(slot.word.startIndex, offsetBy: index)
                return slot.word[charIndex]
            }
        }

        return nil
    }
    
    /// Get completed word at a grid position (for word definition lookup)
    func completedWordAt(row: Int, col: Int) -> String? {
        let position = GridPosition(row: row, col: col)
        
        for slot in gameState.wordSlots {
            if slot.contains(position: position) && slot.isFilled {
                return slot.word
            }
        }
        
        return nil
    }
}
