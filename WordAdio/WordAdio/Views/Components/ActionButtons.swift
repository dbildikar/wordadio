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
            
            // Hint button with timer
            HintButton(
                viewModel: viewModel,
                size: buttonSize
            )
        }
    }
}

/// Hint button that shows countdown timer when hint is locked
struct HintButton: View {
    @ObservedObject var viewModel: GameViewModel
    let size: CGFloat
    
    var body: some View {
        Button(action: { viewModel.useHint() }) {
            ZStack {
                if viewModel.freeHintAvailable {
                    // Hint available - show lightbulb
                    Image(systemName: "lightbulb.fill")
                        .font(Typography.actionButtonIcon)
                        .foregroundColor(.yellow)
                } else {
                    // Hint locked - show countdown
                    Text("\(viewModel.secondsUntilFreeHint)")
                        .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(
                        viewModel.freeHintAvailable
                            ? AppColors.hintButtonGradient
                            : LinearGradient(
                                colors: [.gray.opacity(0.6), .gray.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
            )
            .overlay(
                // Circular progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(60 - viewModel.secondsUntilFreeHint) / 60.0)
                    .stroke(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .opacity(viewModel.freeHintAvailable ? 0 : 1)
            )
            .shadow(
                color: viewModel.freeHintAvailable ? .orange.opacity(0.3) : .gray.opacity(0.2),
                radius: 4,
                y: 2
            )
            .animation(.easeInOut(duration: 0.3), value: viewModel.freeHintAvailable)
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
