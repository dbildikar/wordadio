import SwiftUI

/// View for displaying the crossword-style puzzle board
struct PuzzleBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    
    // Track positions that should be highlighted
    private var highlightedPositions: Set<GridPosition> {
        viewModel.lastFilledPositions
    }

    var body: some View {
        let gridSize = viewModel.gameState.puzzle.gridSize

        GeometryReader { geometry in
            let cellSize = min(
                geometry.size.width / CGFloat(gridSize.cols),
                geometry.size.height / CGFloat(gridSize.rows)
            )

            VStack(spacing: 0) {
                ForEach(0..<gridSize.rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<gridSize.cols, id: \.self) { col in
                            PuzzleCellView(
                                row: row,
                                col: col,
                                cellSize: cellSize,
                                viewModel: viewModel,
                                isHighlighted: highlightedPositions.contains(GridPosition(row: row, col: col))
                            )
                        }
                    }
                }
            }
            .frame(width: CGFloat(gridSize.cols) * cellSize,
                   height: CGFloat(gridSize.rows) * cellSize)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onChange(of: viewModel.lastFilledPositions) { _, _ in
            viewModel.clearFilledPositionsAnimation()
        }
    }
}

/// Individual cell in the puzzle grid
struct PuzzleCellView: View {
    let row: Int
    let col: Int
    let cellSize: CGFloat
    @ObservedObject var viewModel: GameViewModel
    let isHighlighted: Bool
    @Environment(\.onWordTapped) private var onWordTapped
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0

    var body: some View {
        let isInPuzzle = viewModel.isPositionInPuzzle(row: row, col: col)
        let character = viewModel.characterAt(row: row, col: col)
        let solutionChar = viewModel.solutionCharacterAt(row: row, col: col)
        let isFilled = character != nil
        let completedWord = viewModel.completedWordAt(row: row, col: col)

        ZStack {
            if isInPuzzle {
                // Glow effect for highlighted cells
                if isHighlighted {
                    RoundedRectangle(cornerRadius: LayoutMetrics.puzzleCellCornerRadius)
                        .fill(Color.green.opacity(glowOpacity))
                        .blur(radius: 4)
                        .scaleEffect(1.2)
                }
                
                // Base tile with shadow
                RoundedRectangle(cornerRadius: LayoutMetrics.puzzleCellCornerRadius)
                    .fill(isFilled ? AppColors.filledTileColor : AppColors.emptyTileColor)
                    .shadow(
                        color: isHighlighted ? Color.green.opacity(0.5) : AppShadows.tileShadow.color,
                        radius: isHighlighted ? 6 : AppShadows.tileShadow.radius,
                        x: AppShadows.tileShadow.x,
                        y: AppShadows.tileShadow.y
                    )
                
                // Bevel highlight (top-left)
                RoundedRectangle(cornerRadius: LayoutMetrics.puzzleCellCornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(isFilled ? 0.6 : 0.8), location: 0),
                                .init(color: Color.clear, location: 0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(1)
                
                // Bevel shadow (bottom-right)
                RoundedRectangle(cornerRadius: LayoutMetrics.puzzleCellCornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.clear, location: 0.6),
                                .init(color: Color.black.opacity(0.12), location: 1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(1)
                
                // Border with gradient
                RoundedRectangle(cornerRadius: LayoutMetrics.puzzleCellCornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.gray.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )

                // Filled character
                if let char = character {
                    Text(String(char))
                        .font(.system(size: cellSize * Typography.puzzleCellFontMultiplier, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .shadow(color: .white.opacity(0.5), radius: 0, x: 0, y: 1)
                        .transition(.scale.combined(with: .opacity))
                        .scaleEffect(pulseScale)
                }

                // Solution character (developer mode)
                if viewModel.developerSettings.showSolution,
                   let solChar = solutionChar,
                   character == nil {
                    Text(String(solChar))
                        .font(.system(size: cellSize * Typography.puzzleSolutionFontMultiplier, weight: .regular, design: .rounded))
                        .foregroundColor(.gray.opacity(0.5))
                }
            } else {
                // Empty space outside puzzle
                Color.clear
            }
        }
        .frame(width: cellSize, height: cellSize)
        .scaleEffect(isHighlighted ? 1.1 : 1.0)
        .animation(AnimationSprings.smooth, value: character)
        .animation(AnimationSprings.bouncy, value: isHighlighted)
        .onChange(of: isHighlighted) { _, newValue in
            if newValue {
                // Trigger pulse animation
                withAnimation(.easeOut(duration: AnimationDurations.quick)) {
                    pulseScale = 1.3
                    glowOpacity = 0.6
                }
                withAnimation(.easeInOut(duration: AnimationDurations.standard).delay(AnimationDurations.quick)) {
                    pulseScale = 1.0
                    glowOpacity = 0
                }
            }
        }
        .onTapGesture {
            if let word = completedWord {
                HapticManager.shared.lightTap()
                onWordTapped(word)
            }
        }
    }
}

#Preview {
    PuzzleBoardView(viewModel: GameViewModel())
        .frame(height: 400)
        .background(Color.gray.opacity(0.1))
}
