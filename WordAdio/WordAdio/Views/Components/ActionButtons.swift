import SwiftUI

/// Vertical stack of action buttons (shuffle, bonus, hint)
struct ActionButtons: View {
    @ObservedObject var viewModel: GameViewModel
    let onShowBonusWords: () -> Void
    
    private var buttonSize: CGFloat {
        LayoutMetrics.actionButtonSize
    }
    
    var body: some View {
        VStack(spacing: LayoutMetrics.actionButtonSpacing) {
            // Shuffle button
            ActionButton(
                icon: "shuffle",
                iconColor: .white,
                gradient: AppColors.shuffleButtonGradient,
                shadowColor: .purple.opacity(0.3),
                size: buttonSize
            ) {
                viewModel.shuffleWheel()
            }
            
            // Bonus words button
            Button(action: onShowBonusWords) {
                ZStack {
                    Image(systemName: "star.fill")
                        .font(Typography.actionButtonIcon)
                        .foregroundColor(.white)
                    if viewModel.gameState.bonusWords.count > 0 {
                        Text("\(viewModel.gameState.bonusWords.count)")
                            .font(Typography.badge)
                            .foregroundColor(.white)
                            .frame(width: LayoutMetrics.badgeSize, height: LayoutMetrics.badgeSize)
                            .background(Circle().fill(Color.red))
                            .offset(x: buttonSize * 0.4, y: -buttonSize * 0.4)
                    }
                }
                .frame(width: buttonSize, height: buttonSize)
                .background(Circle().fill(AppColors.bonusButtonGradient))
                .shadow(color: .orange.opacity(0.3), radius: 4, y: 2)
            }
            
            // Hint button
            ActionButton(
                icon: "lightbulb.fill",
                iconColor: .yellow,
                gradient: AppColors.hintButtonGradient,
                shadowColor: .orange.opacity(0.3),
                size: buttonSize
            ) {
                viewModel.useHint()
            }
        }
    }
}

/// Reusable circular action button
struct ActionButton: View {
    let icon: String
    let iconColor: Color
    let gradient: LinearGradient
    let shadowColor: Color
    let size: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(Typography.actionButtonIcon)
                .foregroundColor(iconColor)
                .frame(width: size, height: size)
                .background(Circle().fill(gradient))
                .shadow(color: shadowColor, radius: 4, y: 2)
        }
    }
}

#Preview {
    ActionButtons(
        viewModel: GameViewModel(),
        onShowBonusWords: {}
    )
    .padding()
    .background(Color.gray.opacity(0.2))
}
