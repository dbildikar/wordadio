import SwiftUI

/// Sheet for displaying word definitions
struct WordDefinitionSheet: View {
    let word: String
    let definition: WordDefinition?
    let isLoading: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.97),
                        Color(red: 0.90, green: 0.90, blue: 0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Word title
                        Text(word.uppercased())
                            .font(.largeTitle.bold())
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        if isLoading {
                            loadingView
                        } else if let def = definition {
                            definitionContent(def)
                        } else {
                            notFoundView
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: shareWord) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer(minLength: 60)
            ProgressView()
                .scaleEffect(1.2)
            Text("Looking up definition...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer(minLength: 60)
        }
    }
    
    private func definitionContent(_ def: WordDefinition) -> some View {
        VStack(spacing: 16) {
            // Phonetic
            if let phonetic = def.phonetic {
                Text(phonetic)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Part of speech
            if let pos = def.partOfSpeech {
                Text(pos.capitalized)
                    .font(.subheadline.italic())
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.blue.opacity(0.1)))
            }
            
            // Definition
            if let defText = def.definition {
                infoCard(title: "Definition", content: defText)
            }
            
            // Example
            if let example = def.example {
                infoCard(title: "Example", content: "\"\(example)\"", isItalic: true)
            }
            
            Spacer(minLength: 20)
        }
    }
    
    private func infoCard(title: String, content: String, isItalic: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.secondary)
            Group {
                if isItalic {
                    Text(content)
                        .font(.body.italic())
                        .foregroundColor(.primary.opacity(0.8))
                } else {
                    Text(content)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .padding(.horizontal, 20)
    }
    
    private var notFoundView: some View {
        VStack {
            Spacer(minLength: 60)
            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            Text("Definition not found")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer(minLength: 60)
        }
    }
    
    private func shareWord() {
        ShareManager.shared.shareWord(word, isBonus: false)
    }
}

#Preview {
    WordDefinitionSheet(
        word: "EXAMPLE",
        definition: WordDefinition(
            word: "example",
            phonetic: "/ɪɡˈzæmpəl/",
            partOfSpeech: "noun",
            definition: "A thing characteristic of its kind or illustrating a general rule.",
            example: "This is a good example of the word."
        ),
        isLoading: false
    )
}
