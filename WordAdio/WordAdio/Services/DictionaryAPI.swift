import Foundation

/// Service for fetching word definitions from the Free Dictionary API
class DictionaryAPI {
    static let shared = DictionaryAPI()
    
    private let baseURL = "https://api.dictionaryapi.dev/api/v2/entries/en/"
    private var cache: [String: WordDefinition] = [:]
    
    private init() {}
    
    /// Fetches the definition for a word
    func getDefinition(for word: String) async -> WordDefinition? {
        let lowercased = word.lowercased()
        
        // Check cache first
        if let cached = cache[lowercased] {
            return cached
        }
        
        guard let url = URL(string: baseURL + lowercased) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let responses = try JSONDecoder().decode([DictionaryResponse].self, from: data)
            
            guard let first = responses.first else { return nil }
            
            // Extract the first definition
            let definition = WordDefinition(
                word: first.word,
                phonetic: first.phonetic ?? first.phonetics?.first { $0.text != nil }?.text,
                partOfSpeech: first.meanings?.first?.partOfSpeech,
                definition: first.meanings?.first?.definitions?.first?.definition,
                example: first.meanings?.first?.definitions?.first?.example
            )
            
            // Cache it
            cache[lowercased] = definition
            
            return definition
        } catch {
            return nil
        }
    }
}

// MARK: - Models

struct WordDefinition {
    let word: String
    let phonetic: String?
    let partOfSpeech: String?
    let definition: String?
    let example: String?
}

// MARK: - API Response Models

private struct DictionaryResponse: Codable {
    let word: String
    let phonetic: String?
    let phonetics: [Phonetic]?
    let meanings: [Meaning]?
}

private struct Phonetic: Codable {
    let text: String?
    let audio: String?
}

private struct Meaning: Codable {
    let partOfSpeech: String?
    let definitions: [Definition]?
}

private struct Definition: Codable {
    let definition: String?
    let example: String?
}
