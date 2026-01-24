import SwiftUI

/// Developer tools sheet for testing and debugging
struct DeveloperToolsView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                levelControlsSection
                displaySection
                puzzleInfoSection
                solutionWordsSection
                possibleWordsSection
                statisticsSection
            }
            .navigationTitle("Developer Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var levelControlsSection: some View {
        Section("Level Controls") {
            Button("Reset Level") {
                viewModel.resetLevel()
                dismiss()
            }

            Button("Auto-Solve Level") {
                viewModel.autoSolve()
                dismiss()
            }

            Button("Next Level") {
                viewModel.loadNextLevel()
                dismiss()
            }
        }
    }
    
    private var displaySection: some View {
        Section("Display") {
            Toggle("Show Solution", isOn: $viewModel.developerSettings.showSolution)
        }
    }
    
    private var puzzleInfoSection: some View {
        Section("Puzzle Info") {
            Text("Base Word: \(viewModel.gameState.puzzle.baseWord)")
            Text("Grid Size: \(viewModel.gameState.puzzle.gridSize.rows) × \(viewModel.gameState.puzzle.gridSize.cols)")
            Text("Total Slots: \(viewModel.gameState.wordSlots.count)")
            Text("Filled Slots: \(viewModel.gameState.wordSlots.filter { $0.isFilled }.count)")
        }
    }
    
    private var solutionWordsSection: some View {
        Section("Solution Words") {
            ForEach(viewModel.gameState.wordSlots, id: \.id) { slot in
                HStack {
                    Text(slot.word)
                        .font(.body.monospaced())
                    Spacer()
                    Image(systemName: slot.isFilled ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(slot.isFilled ? .green : .gray)
                }
            }
        }
    }
    
    private var possibleWordsSection: some View {
        Section("All Possible Words") {
            let possibleWords = viewModel.getPossibleWords().sorted()
            ForEach(possibleWords, id: \.self) { word in
                Text(word)
                    .font(.caption.monospaced())
            }
        }
    }
    
    private var statisticsSection: some View {
        Section("Statistics") {
            Text("Total Coins: \(viewModel.progress.coins)")
            Text("Longest Word: \(viewModel.progress.longestWord)")
            Text("Total Bonus Words: \(viewModel.progress.totalBonusWords)")
            Text("Completed Levels: \(viewModel.progress.completedLevels.count)")
            Text("Current Streak: \(viewModel.progress.consecutiveCompletedLevels)")
        }
    }
}

#Preview {
    DeveloperToolsView(viewModel: GameViewModel())
}
