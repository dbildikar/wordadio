# Quick Start Guide

## Opening and Running the Game

1. **Open in Xcode**
   ```bash
   cd /Users/darshanbildikar/code/wordadio/WordPuzzle
   open WordPuzzle.xcodeproj
   ```

2. **Select a Simulator**
   - Click the device selector in Xcode's toolbar (top-left)
   - Choose any iPhone simulator (e.g., "iPhone 16 Pro")

3. **Run the App**
   - Press `⌘R` or click the Run (▶) button
   - The app will build and launch in the iOS Simulator

## How to Play

### Game Objective
Fill all crossword-style slots on the puzzle board by forming valid words from the circular letter wheel.

### Controls
- **Tap** individual letters to select them
- **Drag** across multiple letters to form words
- **Submit** to confirm your word (green button)
- **Clear** to deselect current letters (red button)
- **Shuffle** to rearrange wheel letters (orange button)

### Scoring
- Puzzle words: **10 points per letter**
- Bonus words: **20 points per letter** (words not in the puzzle but valid)
- Level completion: **100 bonus points**

### Level Progression
- Complete all puzzle slots to finish a level
- Next level loads automatically after 2 seconds
- Track your streak in the top-right corner

## Developer Tools

Click "Developer Tools" button at the bottom of the screen to access:

- **Show Solution**: Display faded solution letters in empty cells
- **Auto-Solve**: Automatically fill all puzzle words
- **Reset Level**: Start current level over
- **Next Level**: Skip to next level
- **Solution Words**: View all required words with completion status
- **All Possible Words**: See every valid word that can be formed
- **Statistics**: View your progress and achievements

## Testing in Simulator

### Mouse/Trackpad Controls
- **Click**: Select individual letters
- **Click and Drag**: Select multiple letters in sequence
- **Release**: Complete letter selection

### Recommended Simulator
- iPhone 16 Pro (or any recent iPhone model)
- iOS 17.0 or later

## Troubleshooting

### Build Fails
- Clean build folder: `⌘⇧K`
- Rebuild: `⌘B`

### Simulator Issues
- Close and reopen simulator
- Reset simulator: Device → Erase All Content and Settings

### Dictionary Not Loading
- Check console for "Dictionary loaded" message
- Fallback dictionary activates automatically if JSON fails

## Project Structure

```
WordPuzzle/
├── WordPuzzle/
│   ├── Models/              # Data structures
│   ├── Services/            # Dictionary, Level Generator, Persistence
│   ├── ViewModels/          # Game logic (MVVM)
│   ├── Views/               # SwiftUI views
│   └── Resources/           # dictionary.json
├── WordPuzzleTests/         # Unit tests
└── README.md               # Full documentation
```

## Sample Levels

### Level 1: SPRING
```
S P I N
P R I N G
  I
  P
```

### Level 2: GRAINS
```
G R A I N S
  A     A
  I     I
  N     N
```

### Level 3: PLANTS
```
P L A N T S
L L A
A S N
N   T
```

Levels 4-5 are predefined, Level 6+ are procedurally generated.

## Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Explore the code in Xcode
- Try adding new words to `Resources/dictionary.json`
- Customize scoring in `Models.swift`
- Adjust difficulty in `LevelGenerator.swift`

Enjoy the game!
