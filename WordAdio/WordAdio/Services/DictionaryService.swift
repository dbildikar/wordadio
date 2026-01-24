import Foundation

/// Service for managing the word dictionary and validation
/// Uses a hash set for O(1) word lookups
class DictionaryService {
    static let shared = DictionaryService()

    // Large validation dictionary from words.txt (O(1) lookup)
    private var validationWordSet: Set<String> = []

    // Curated words for puzzle generation from common-words.txt
    private var wordsByLength: [Int: [String]] = [:]

    // 6-letter base words for puzzle generation
    private var sixLetterWords: [String] = []

    private init() {
        loadValidationDictionary()
        loadPuzzleDictionary()
        loadSixLetterWords()
    }

    /// Load large validation dictionary from words.txt
    /// Contains ~466K words for bonus word validation
    private func loadValidationDictionary() {
        guard let url = Bundle.main.url(forResource: "words", withExtension: "txt") else {
            loadFallbackDictionary()
            return
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let words = content.components(separatedBy: .newlines)

            // Filter and normalize: only keep alphabetic words 3+ letters
            validationWordSet = Set(
                words
                    .map { $0.uppercased().trimmingCharacters(in: .whitespaces) }
                    .filter { word in
                        word.count >= 3 &&
                        word.allSatisfy { $0.isLetter }
                    }
            )
        } catch {
            loadFallbackDictionary()
        }
    }

    /// Load curated puzzle dictionary from common-words.txt
    /// Contains ~10,000 common English words for puzzle generation
    private func loadPuzzleDictionary() {
        guard let url = Bundle.main.url(forResource: "common-words", withExtension: "txt") else {
            loadFallbackDictionary()
            return
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let words = content.components(separatedBy: .newlines)

            // Organize words by length for efficient puzzle generation
            // Only include words 3-6 letters that are purely alphabetic
            for word in words {
                let normalized = word.uppercased().trimmingCharacters(in: .whitespaces)
                let length = normalized.count
                
                // Only include words 3-6 letters, purely alphabetic
                guard length >= 3 && length <= 6 else { continue }
                guard normalized.allSatisfy({ $0.isLetter }) else { continue }
                
                if wordsByLength[length] == nil {
                    wordsByLength[length] = []
                }
                wordsByLength[length]?.append(normalized)
            }
        } catch {
            loadFallbackDictionary()
        }
    }

    /// Load 6-letter base words for puzzle generation
    private func loadSixLetterWords() {
        guard let url = Bundle.main.url(forResource: "six-letter-words", withExtension: "json") else {
            sixLetterWords = ["SPRING", "TRAINS", "PLANTS", "STRAND", "SEARCH", "DREAMS", "MASTER", "GRAINS"]
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let words = try decoder.decode([String].self, from: data)
            sixLetterWords = words.map { $0.uppercased() }
        } catch {
            sixLetterWords = ["SPRING", "TRAINS", "PLANTS", "STRAND", "SEARCH", "DREAMS", "MASTER", "GRAINS"]
        }
    }

    /// Fallback dictionary for testing if JSON fails to load
    private func loadFallbackDictionary() {
        let fallbackWords = [
            // 6-letter words
            "SPRING", "GRAINS", "PLANTS", "STRAND", "SEARCH", "REMAIN",
            "TRAINS", "STRAIN", "ARCHES", "MASTER", "STREAM", "WINTER",

            // 5-letter words
            "GRAIN", "TRAIN", "STAIN", "RINGS", "BRING", "STING",
            "PRINT", "GRAND", "PLANT", "ARCH", "MARCH", "REACH",
            "MAST", "STREAM", "REAM", "TEAM", "SEAM", "TERM",

            // 4-letter words
            "RING", "SING", "TING", "PING", "RAIN", "GAIN",
            "PAIN", "MAIN", "STAR", "RANG", "HANG", "BANG",
            "ARCS", "CARS", "MARS", "TEAM", "SEAM", "REAM",
            "MAST", "CAST", "EAST", "SEAR", "TEAR", "STEM",

            // 3-letter words
            "SIN", "TIN", "PIN", "RIG", "SIG", "RAG",
            "TAG", "SAG", "NAG", "GAP", "SAP", "TAP",
            "ARC", "CAR", "MAR", "EAR", "TEA", "SEA",
            "SET", "MET", "MAT", "SAT", "RAT", "EAT"
        ]

        validationWordSet = Set(fallbackWords)
        for word in fallbackWords {
            let length = word.count
            if wordsByLength[length] == nil {
                wordsByLength[length] = []
            }
            wordsByLength[length]?.append(word)
        }
    }

    /// Check if a word exists in the dictionary
    /// Uses the large validation dictionary from words.txt for O(1) lookup
    /// - Parameter word: The word to validate (case-insensitive)
    /// - Returns: true if the word exists
    func isValidWord(_ word: String) -> Bool {
        let normalized = word.uppercased().trimmingCharacters(in: .whitespaces)
        return validationWordSet.contains(normalized)
    }

    /// Get all words of a specific length
    /// - Parameter length: The word length
    /// - Returns: Array of words with the specified length
    func words(ofLength length: Int) -> [String] {
        return wordsByLength[length] ?? []
    }

    /// Get all words that can be formed from a set of letters
    /// - Parameters:
    ///   - letters: Available letters
    ///   - minLength: Minimum word length (default: 3)
    ///   - maxLength: Maximum word length (default: length of letters)
    /// - Returns: Array of valid words
    func findWords(from letters: [Character], minLength: Int = 3, maxLength: Int? = nil) -> [String] {
        let max = maxLength ?? letters.count
        var validWords: [String] = []

        for length in minLength...max {
            let wordsOfLength = words(ofLength: length)
            for word in wordsOfLength {
                if canFormWord(word, from: letters) {
                    validWords.append(word)
                }
            }
        }

        return validWords
    }

    /// Check if a word can be formed from available letters
    /// - Parameters:
    ///   - word: The word to check
    ///   - letters: Available letters
    /// - Returns: true if the word can be formed
    func canFormWord(_ word: String, from letters: [Character]) -> Bool {
        var availableLetters = letters.map { String($0).uppercased().first! }
        let wordChars = Array(word.uppercased())

        for char in wordChars {
            if let index = availableLetters.firstIndex(of: char) {
                availableLetters.remove(at: index)
            } else {
                return false
            }
        }

        return true
    }

    /// Find words that can be formed from letters and match a specific pattern
    /// - Parameters:
    ///   - letters: Available letters
    ///   - pattern: Pattern with wildcards (e.g., "_A_" for 3-letter words with A in middle)
    /// - Returns: Array of matching words
    func findWordsMatching(pattern: String, from letters: [Character]) -> [String] {
        let length = pattern.count
        let wordsOfLength = words(ofLength: length)
        var matches: [String] = []

        for word in wordsOfLength {
            if matchesPattern(word, pattern: pattern) && canFormWord(word, from: letters) {
                matches.append(word)
            }
        }

        return matches
    }

    /// Check if a word matches a pattern
    private func matchesPattern(_ word: String, pattern: String) -> Bool {
        let wordChars = Array(word)
        let patternChars = Array(pattern)

        guard wordChars.count == patternChars.count else { return false }

        for i in 0..<wordChars.count {
            if patternChars[i] != "_" && patternChars[i] != wordChars[i] {
                return false
            }
        }

        return true
    }

    /// Get a random word of specific length
    /// - Parameter length: Word length
    /// - Returns: Random word or nil if none available
    func randomWord(ofLength length: Int, seed: UInt64? = nil) -> String? {
        let wordsOfLength = words(ofLength: length)
        guard !wordsOfLength.isEmpty else { return nil }

        if let seed = seed {
            var generator = SeededRandomGenerator(seed: seed)
            let index = Int.random(in: 0..<wordsOfLength.count, using: &generator)
            return wordsOfLength[index]
        } else {
            return wordsOfLength.randomElement()
        }
    }

    /// Get a base 6-letter word for a given level
    /// Uses level number as seed for deterministic selection
    /// - Parameter levelNumber: The level number
    /// - Returns: 6-letter base word
    func getBaseWord(for levelNumber: Int) -> String {
        return getRandomBaseWord(excluding: [], seed: UInt64(levelNumber))
    }
    
    /// Get a random base word, optionally excluding certain words
    /// - Parameters:
    ///   - excluding: Set of words to exclude
    ///   - seed: Random seed for deterministic selection
    /// - Returns: 6-letter base word
    func getRandomBaseWord(excluding: Set<String> = [], seed: UInt64) -> String {
        guard !sixLetterWords.isEmpty else {
            return "SPRING"
        }

        // Filter to ensure only 6-letter words and exclude specified words
        let validSixLetterWords = sixLetterWords.filter { $0.count == 6 && !excluding.contains($0) }
        guard !validSixLetterWords.isEmpty else {
            // If all words are excluded, fall back to any 6-letter word
            let fallbackWords = sixLetterWords.filter { $0.count == 6 }
            guard !fallbackWords.isEmpty else {
                return "SPRING"
            }
            var generator = SeededRandomGenerator(seed: seed)
            let index = Int.random(in: 0..<fallbackWords.count, using: &generator)
            return fallbackWords[index]
        }

        // Use seed for deterministic selection
        var generator = SeededRandomGenerator(seed: seed)
        let index = Int.random(in: 0..<validSixLetterWords.count, using: &generator)
        let selectedWord = validSixLetterWords[index]
        
        // Final validation
        guard selectedWord.count == 6 else {
            return "SPRING"
        }
        
        return selectedWord
    }
}

// MARK: - Supporting Types

private struct DictionaryData: Codable {
    let words: [String]
}

/// Seeded random number generator for deterministic puzzle generation
struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // Linear congruential generator
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
