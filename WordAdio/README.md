# Word Puzzle Game

A complete iOS word puzzle game built with Swift 5+ and SwiftUI. Players form words by dragging across letters in a circular wheel to fill crossword-style puzzle slots.

## Features

- **Crossword-Style Puzzle Board**: Intersecting horizontal and vertical word patterns
- **Circular Letter Wheel**: 5-7 letters arranged in a circle for word formation
- **Touch & Mouse Support**: Fully playable in iOS Simulator
- **Progressive Difficulty**: Automatic level progression with increasing complexity
- **Scoring System**: Points for puzzle words and bonus words
- **Local Persistence**: Progress, scores, and statistics saved locally
- **Developer Tools**: Built-in tools for testing and debugging
- **Unit Tests**: Comprehensive test coverage

## How to Run in iOS Simulator

### Prerequisites

- Xcode 15.0 or later
- macOS 13.0 or later
- iOS 17.0 SDK or later

### Steps

1. **Open the Project**
   ```bash
   cd WordPuzzle
   open WordPuzzle.xcodeproj
   ```

2. **Select Simulator**
   - In Xcode, click the scheme selector (top-left)
   - Choose any iPhone simulator (e.g., "iPhone 15 Pro")

3. **Build and Run**
   - Press `⌘R` or click the Play button
   - The app will compile and launch in the simulator

4. **Playing the Game**
   - **Tap** individual letters to select them
   - **Drag** across letters to form words
   - **Submit** button confirms your word
   - **Clear** removes current selection
   - **Shuffle** randomizes letter positions
   - **Developer Tools** button (bottom) opens testing features

### Controls

- **Mouse**: Click and drag letters in the wheel
- **Trackpad**: Tap and drag gestures work naturally
- **Keyboard**: Not required (touch-first design)

## Game Rules

### Objective

Fill all crossword slots on the puzzle board by forming valid words from the letter wheel.

### Word Formation

1. Letters must be in the dictionary
2. Words must be at least 3 letters long
3. Each letter position can only be used once per word
4. Letters can be reused across different words

### Scoring

- **Puzzle Words**: 10 points per letter
- **Bonus Words**: 20 points per letter (2x multiplier)
- **Level Completion**: 100 bonus points

### Level Completion

- A level completes when all puzzle slots are filled
- Bonus words do not fill slots but add to your score
- Next level loads automatically after completion

## Architecture

### MVVM Pattern

```
Models/
  ├── Models.swift          - Data structures (Word, Puzzle, Level, etc.)

Services/
  ├── DictionaryService.swift   - Word validation (hash set)
  ├── LevelGenerator.swift      - Puzzle generation algorithm
  └── PersistenceManager.swift  - Local storage

ViewModels/
  └── GameViewModel.swift       - Game logic and state

Views/
  ├── ContentView.swift         - Main game screen
  ├── PuzzleBoardView.swift     - Crossword grid display
  └── LetterWheelView.swift     - Circular letter input
```

## Puzzle Generation Algorithm

The puzzle generator creates guaranteed-solvable crossword-style layouts:

### Algorithm Steps

1. **Select Base Word**
   - Choose a random 6-letter word from dictionary
   - This becomes the primary horizontal word at position (0, 0)

2. **Find Intersecting Words**
   - For each letter in the base word:
     - Search for words containing that letter
     - Verify words can be formed from base word letters
     - Place vertically to create crossword intersection

3. **Build Grid**
   - Track all occupied positions
   - Calculate grid dimensions (rows × cols)
   - Adjust positions to start from (0, 0)

4. **Extract Wheel Letters**
   - Take unique letters from base word
   - Ensure 5-7 letters total
   - Shuffle for randomization

5. **Validate Puzzle**
   - Verify all words are in dictionary
   - Confirm all words can be formed from wheel letters
   - Check intersection points have matching characters

### Predefined vs. Generated

- **Levels 1-5**: Predefined puzzles for consistency
- **Level 6+**: Procedurally generated
- **Seeded RNG**: Deterministic generation for testing

### Example: Level 1 (SPRING)

```
S P I N
P R I N G
  I
  P
```

- Base word: SPRING (horizontal)
- Intersecting words: SPIN, RING, GRIP, PIG (vertical)
- Wheel letters: S, P, R, I, N, G

## Dictionary System

### Implementation

- **Data Structure**: Hash set for O(1) lookups
- **Format**: JSON array of uppercase words
- **Categories**: Organized by length (3-6+ letters)

### Current Dictionary

The embedded dictionary contains ~250 common English words optimized for gameplay:

- 6-letter words: SPRING, GRAINS, PLANTS, STRAND, etc.
- 5-letter words: GRAIN, TRAIN, STAIN, RINGS, etc.
- 4-letter words: RING, SING, RAIN, STAR, etc.
- 3-letter words: SIN, TIN, PIN, RIG, etc.

### Expanding the Dictionary

To add more words:

1. **Edit JSON File**
   ```
   WordPuzzle/Resources/dictionary.json
   ```

2. **Add Words to Array**
   ```json
   {
     "words": [
       "SPRING",
       "NEWWORD",
       ...
     ]
   }
   ```

3. **Guidelines**
   - Use uppercase letters only
   - Common English words preferred
   - Avoid proper nouns, abbreviations
   - Include variety of lengths (3-8 letters)

4. **Rebuild**
   - Clean build folder (`⌘⇧K`)
   - Rebuild project (`⌘B`)

### Adding a Full Dictionary

For a comprehensive word list:

```bash
# Example: Add Scrabble dictionary (SOWPODS)
curl -o scrabble.txt https://example.com/sowpods.txt

# Convert to JSON
python3 -c "
import json
words = [w.strip().upper() for w in open('scrabble.txt')]
words = [w for w in words if 3 <= len(w) <= 8]  # Filter lengths
with open('WordPuzzle/Resources/dictionary.json', 'w') as f:
    json.dump({'words': words}, f, indent=2)
"
```

## Developer Tools

Access via the "Developer Tools" button at the bottom of the screen.

### Features

- **Show Solution**: Display faded solution letters in grid
- **Reset Level**: Restart current level from scratch
- **Auto-Solve**: Automatically fill all puzzle words
- **Next Level**: Skip to next level
- **Puzzle Info**: View grid size, slot counts
- **Solution Words**: See all required words and completion status
- **All Possible Words**: View every valid word formable from wheel
- **Statistics**: Track total score, longest word, bonus words

### Seeded Random Generation

For deterministic testing:

```swift
// In GameViewModel.swift init
let viewModel = GameViewModel(seed: 12345)
```

Same seed produces identical puzzles for reproducible tests.

## Testing

### Running Unit Tests

1. Press `⌘U` in Xcode, or
2. Product → Test from menu

### Test Coverage

- **Dictionary Tests**: Word validation, letter matching
- **Puzzle Generation**: Solvability, determinism
- **Game Logic**: Word filling, level completion, scoring
- **Wheel Input**: Letter selection, deselection
- **Persistence**: Save/load progress
- **Grid Position**: Coordinate calculations

### Key Test Cases

```swift
testWordValidation()           // Dictionary lookups
testPuzzleSolvability()        // All words formable
testDeterministicGeneration()  // Seeded RNG
testLevelCompletion()          // Win condition
testLetterSelection()          // Input logic
```

## Sample Levels

### Level 1: SPRING
- Base: SPRING
- Words: SPRING, SPIN, RING, GRIP, PIG
- Difficulty: Beginner

### Level 2: GRAINS
- Base: GRAINS
- Words: GRAINS, GAIN, RAIN, SIN, RANG
- Difficulty: Beginner

### Level 3: PLANTS
- Base: PLANTS
- Words: PLANTS, PLAN, LAST, ANTS, SLAP
- Difficulty: Easy

### Level 4: STRAND
- Base: STRAND
- Words: STRAND, STAR, RANT, RAND, ARTS
- Difficulty: Easy

### Level 5: SEARCH
- Base: SEARCH
- Words: SEARCH, SEAR, EACH, ARCH, ACHE
- Difficulty: Medium

Levels 6+ are procedurally generated with increasing difficulty.

## Persistence

### Saved Data

Progress is automatically saved using UserDefaults:

- Current level number
- Total score
- Bonus word count
- Longest word found
- Consecutive level streak
- Completed level set
- Last played date

### Clearing Progress

Via Developer Tools or programmatically:

```swift
PersistenceManager.shared.clearProgress()
```

## Customization

### Adjust Difficulty

Edit `LevelGenerator.swift`:

```swift
// Minimum word length per level
let wordLength = 3 + (levelNumber / 5)

// Number of intersecting words
let maxIntersections = min(5, 2 + levelNumber / 3)
```

### Change Scoring

Edit `Models.swift`:

```swift
enum ScoringRules {
    static let pointsPerLetter = 10
    static let bonusWordMultiplier = 2
    static let levelCompletionBonus = 100
}
```

### Wheel Size

Edit `LetterWheelView.swift`:

```swift
private let wheelRadius: CGFloat = 130  // Increase for larger wheel
private let letterRadius: CGFloat = 35  // Increase for bigger buttons
```

## Troubleshooting

### Dictionary Not Loading

**Symptom**: "Error: dictionary.json not found" in console

**Solution**:
1. Clean build folder (`⌘⇧K`)
2. Verify file in Project Navigator
3. Check Target Membership (File Inspector)
4. Rebuild project

### No Words Found

**Symptom**: All words marked as invalid

**Solution**:
- Dictionary fallback should activate automatically
- Check console for "Fallback dictionary loaded"
- Verify dictionary.json format (valid JSON)

### Puzzle Won't Generate

**Symptom**: Blank screen or error on level load

**Solution**:
- Check dictionary has sufficient 6-letter words
- Review console for generation errors
- Try Developer Tools → Reset Level

### Simulator Performance

**Symptom**: Laggy animations

**Solution**:
- Use newer simulator (iPhone 15+)
- Disable Metal API Validation (Xcode Scheme settings)
- Reduce animation complexity in Settings

## License

This project is provided as educational sample code. Free to use and modify.

## Credits

Built with Swift 5, SwiftUI, and Xcode 15.

No external dependencies or third-party frameworks used.
