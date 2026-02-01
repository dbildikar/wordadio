import SwiftUI

/// Overlay displayed when a level is completed
struct LevelCompleteView: View {
    let stats: GameViewModel.LevelCompleteStats
    let onContinue: () -> Void
    
    @State private var showContent = false
    @State private var showStars = false
    @State private var showStats = false
    @State private var showButton = false
    @State private var starRotations: [Double] = [0, 0, 0]
    @State private var confettiTrigger = false
    
    private var starLegend: String {
        switch stats.starCount {
        case 3:
            return "Perfect! No hints + Bonus words"
        case 2:
            if stats.bonusWords > 0 {
                return "Great! Found bonus words"
            } else {
                return "Great! No hints used"
            }
        default:
            return "Complete!"
        }
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onContinue()
                }
            
            // Confetti particles
            ConfettiView(trigger: confettiTrigger)
            
            // Main content
            VStack(spacing: 24) {
                starsSection
                levelCompleteText
                statsCard
                continueButton
            }
            .padding(32)
        }
        .onAppear {
            animateEntrance()
        }
    }
    
    // MARK: - Subviews
    
    private var starsSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { index in
                    let isEarned = index < stats.starCount
                    Image(systemName: isEarned ? "star.fill" : "star")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            isEarned ?
                                AnyShapeStyle(AppColors.coinGradient) :
                                AnyShapeStyle(Color.gray.opacity(0.4))
                        )
                        .shadow(color: isEarned ? .orange.opacity(0.5) : .clear, radius: 10)
                        .scaleEffect(showStars ? 1.0 : 0.0)
                        .rotationEffect(.degrees(isEarned ? starRotations[index] : 0))
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.6)
                                .delay(Double(index) * 0.15),
                            value: showStars
                        )
                }
            }
            
            // Star legend
            Text(starLegend)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .opacity(showStars ? 1 : 0)
                .animation(.easeIn.delay(0.5), value: showStars)
        }
        .padding(.top, 20)
    }
    
    private var levelCompleteText: some View {
        VStack(spacing: 8) {
            Text("Level \(stats.levelNumber)")
                .font(Typography.levelNumber)
                .foregroundColor(.white.opacity(0.8))
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            
            Text("Complete!")
                .font(Typography.levelCompleteTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .yellow],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 5)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.5)
        }
    }
    
    private var statsCard: some View {
        VStack(spacing: 16) {
            StatRow(icon: "checkmark.circle.fill", label: "Words Found", value: "\(stats.wordsFound)", color: .green)
            
            if stats.bonusWords > 0 {
                StatRow(icon: "gift.fill", label: "Bonus Words", value: "+\(stats.bonusWords)", color: .purple)
            }
            
            StatRow(icon: "bitcoinsign.circle.fill", label: "Coins Earned", value: "+\(stats.coinsEarned)", color: .yellow)
            StatRow(icon: "trophy.fill", label: "Completion Bonus", value: "+\(stats.completionBonus)", color: .orange)
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
            
            // Total coins
            HStack {
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppColors.coinGradient)
                Text("Total")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("+\(stats.totalCoins)")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.coinGradient)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20)
        )
        .opacity(showStats ? 1 : 0)
        .offset(y: showStats ? 0 : 30)
    }
    
    private var continueButton: some View {
        VStack(spacing: 12) {
            // Continue button (primary)
            Button(action: onContinue) {
                HStack(spacing: 8) {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(minWidth: 180)
                .padding(.vertical, 16)
                .background(AppColors.primaryGradient)
                .clipShape(Capsule())
                .shadow(color: .purple.opacity(0.4), radius: 10, y: 5)
            }
            
            // Share button (secondary)
            Button(action: shareScore) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Score")
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            }
        }
        .scaleEffect(showButton ? 1 : 0.8)
        .opacity(showButton ? 1 : 0)
    }
    
    private func shareScore() {
        ShareManager.shared.shareLevelComplete(
            level: stats.levelNumber,
            wordsFound: stats.wordsFound,
            bonusWords: stats.bonusWords,
            stars: stats.starCount
        )
    }
    
    // MARK: - Animation
    
    private func animateEntrance() {
        // Trigger confetti
        confettiTrigger = true
        
        // Animate stars with spin
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showStars = true
        }
        
        // Star spin animation
        for i in 0..<3 {
            withAnimation(.easeOut(duration: 0.5).delay(Double(i) * 0.15)) {
                starRotations[i] = 360
            }
        }
        
        // Content fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            showContent = true
        }
        
        // Stats slide up
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5)) {
            showStats = true
        }
        
        // Button appear
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.8)) {
            showButton = true
        }
    }
}

#Preview {
    LevelCompleteView(
        stats: GameViewModel.LevelCompleteStats(
            levelNumber: 5,
            wordsFound: 6,
            bonusWords: 2,
            coinsEarned: 42,
            completionBonus: 45,
            streak: 3,
            hintsUsed: 0
        ),
        onContinue: {}
    )
}
