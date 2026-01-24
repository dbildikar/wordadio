import SwiftUI

/// Header view displaying level, coins, and settings menu
struct HeaderView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showSettings: Bool
    
    // Animation state for coin counter
    @State private var displayedCoins: Int = 0
    @State private var isAnimatingCoins: Bool = false
    @State private var coinScale: CGFloat = 1.0
    @State private var coinGlow: Bool = false
    
    /// Total coins = bank + current level earnings
    private var totalCoins: Int {
        viewModel.progress.coins + viewModel.gameState.coinsEarnedThisLevel
    }

    var body: some View {
        HStack {
            // Settings menu button
            Button(action: { showSettings = true }) {
                Image(systemName: "line.3.horizontal")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    )
            }
            
            // Level indicator
            HStack(spacing: 6) {
                Image(systemName: "flag.fill")
                    .font(.subheadline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("Level \(viewModel.gameState.puzzle.levelNumber)")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            )
            
            Spacer()
            
            // Coins display with animation
            HStack(spacing: 6) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.coinGradient)
                    .scaleEffect(coinScale)
                    .shadow(color: coinGlow ? .yellow.opacity(0.6) : .clear, radius: coinGlow ? 8 : 0)
                
                Text("\(displayedCoins)")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundColor(.primary)
                    .contentTransition(.numericText(countsDown: displayedCoins > totalCoins))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            )
        }
        .onAppear {
            displayedCoins = totalCoins
        }
        .onChange(of: totalCoins) { oldValue, newValue in
            animateCoinChange(from: oldValue, to: newValue)
        }
    }
    
    /// Animate the coin counter from old value to new value
    private func animateCoinChange(from oldValue: Int, to newValue: Int) {
        guard oldValue != newValue else { return }
        
        let isIncreasing = newValue > oldValue
        
        // Trigger glow and scale animation
        withAnimation(.easeOut(duration: 0.15)) {
            coinScale = 1.3
            coinGlow = true
        }
        
        // Animate the number counting
        let difference = abs(newValue - oldValue)
        let steps = min(difference, 20) // Cap at 20 steps for smooth animation
        let stepValue = Double(difference) / Double(steps)
        let stepDuration = 0.4 / Double(steps) // Total animation ~0.4 seconds
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.easeOut(duration: stepDuration)) {
                    if isIncreasing {
                        displayedCoins = oldValue + Int(stepValue * Double(i + 1))
                    } else {
                        displayedCoins = oldValue - Int(stepValue * Double(i + 1))
                    }
                }
            }
        }
        
        // Ensure we land on exact final value
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.1)) {
                displayedCoins = newValue
            }
        }
        
        // Reset scale and glow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                coinScale = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                coinGlow = false
            }
        }
    }
}

#Preview {
    HeaderView(viewModel: GameViewModel(), showSettings: .constant(false))
        .padding()
        .background(Color.gray.opacity(0.2))
}
