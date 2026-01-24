import SwiftUI

/// Sheet displaying found bonus words
struct BonusWordsSheetView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.90, blue: 0.80),
                    Color(red: 0.85, green: 0.75, blue: 0.65)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header with close button
                headerView
                
                // Count badge
                countBadge
                
                // Words display
                if viewModel.gameState.bonusWords.isEmpty {
                    emptyStateView
                } else {
                    wordsListView
                }
                
                Spacer()
                
                // Motivational text
                motivationalText
            }
        }
        .presentationDetents([.fraction(0.4), .medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            withAnimation(AnimationSprings.smooth) {
                showContent = true
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            // Stars + Title
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                    .shadow(color: .orange.opacity(0.5), radius: 4)
                
                Text("Bonus Words")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                    .shadow(color: .orange.opacity(0.5), radius: 4)
            }
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private var countBadge: some View {
        Text("\(viewModel.gameState.bonusWords.count) found")
            .font(.subheadline.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(AppColors.coinGradient)
                    .shadow(color: .orange.opacity(0.3), radius: 4, y: 2)
            )
            .scaleEffect(showContent ? 1 : 0.8)
            .opacity(showContent ? 1 : 0)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.coinGradient)
            Text("No bonus words yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Find words that aren't in the puzzle!")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .padding(.top, 12)
        .opacity(showContent ? 1 : 0)
    }
    
    private var wordsListView: some View {
        Text(viewModel.gameState.bonusWords.sorted().map { $0.uppercased() }.joined(separator: ", "))
            .font(.body)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineSpacing(4)
            .padding(.horizontal, 20)
            .opacity(showContent ? 1 : 0)
    }
    
    private var motivationalText: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkle")
                .font(.caption)
                .foregroundColor(.orange)
            Text("Bonus words earn extra coins!")
                .font(.caption)
                .foregroundColor(.secondary)
            Image(systemName: "sparkle")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .opacity(showContent ? 1 : 0)
        .padding(.bottom, 16)
    }
}

#Preview {
    BonusWordsSheetView(viewModel: GameViewModel())
}
