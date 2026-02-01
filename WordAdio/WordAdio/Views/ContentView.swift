import SwiftUI

/// Main game view containing all UI elements
struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var showDeveloperTools = false
    @State private var showBonusWords = false
    @State private var showSettings = false
    @State private var showAchievements = false
    @State private var showWordDefinition = false
    @State private var selectedWord: String = ""
    @State private var wordDefinition: WordDefinition?
    @State private var isLoadingDefinition = false
    @State private var showAchievementToast = false
    
    var body: some View {
        VStack(spacing: LayoutMetrics.sectionSpacing) {
            // Header (5 taps to access developer tools)
            HeaderView(viewModel: viewModel, showSettings: $showSettings)
                .padding(.horizontal, LayoutMetrics.horizontalPadding)
                .padding(.top, 4)
                .onTapGesture(count: 5) {
                    showDeveloperTools = true
                }
            
            // Middle section: buttons + puzzle
            HStack(alignment: .top, spacing: 8) {
                ActionButtons(
                    viewModel: viewModel,
                    onShowBonusWords: { showBonusWords = true },
                    onShowAchievements: { showAchievements = true }
                )
                PuzzleBoardView(viewModel: viewModel)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            
            // Wheel - constrained height
            LetterWheelView(viewModel: viewModel)
                .frame(maxHeight: LayoutMetrics.wheelMaxHeight)
                .padding(.horizontal, 8)
            
            Spacer(minLength: 0)
            
            // Ad Banner at bottom
            AdBannerContainer()
        }
        .background(
            Image("Background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
        .overlay { messageOverlay }
        .overlay { levelCompleteOverlay }
        .overlay { confettiOverlay }
        .overlay { achievementToastOverlay }
        .onChange(of: viewModel.showConfetti) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    viewModel.showConfetti = false
                }
            }
        }
        .sheet(isPresented: $showDeveloperTools) {
            DeveloperToolsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showBonusWords) {
            BonusWordsSheetView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsSheet()
        }
        .sheet(isPresented: $showWordDefinition) {
            WordDefinitionSheet(
                word: selectedWord,
                definition: wordDefinition,
                isLoading: isLoadingDefinition
            )
        }
        .onAppear {
            SoundManager.shared.startBackgroundMusic()
            ATTManager.shared.requestTrackingPermission()
            GameCenterManager.shared.authenticate()
        }
        .onChange(of: achievementManager.newlyUnlockedAchievement) { _, newValue in
            if newValue != nil {
                showAchievementToast = true
                HapticManager.shared.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showAchievementToast = false
                    achievementManager.newlyUnlockedAchievement = nil
                }
            }
        }
        .environment(\.onWordTapped, { word in
            selectedWord = word
            isLoadingDefinition = true
            showWordDefinition = true
            Task {
                wordDefinition = await DictionaryAPI.shared.getDefinition(for: word)
                isLoadingDefinition = false
            }
        })
    }
    
    // MARK: - Overlay Views
    
    @ViewBuilder
    private var messageOverlay: some View {
        if viewModel.showingMessage {
            MessageOverlay(message: viewModel.message, type: viewModel.messageType)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: viewModel.showingMessage)
        }
    }
    
    @ViewBuilder
    private var levelCompleteOverlay: some View {
        if viewModel.showingLevelComplete, let stats = viewModel.levelCompleteStats {
            LevelCompleteView(stats: stats) {
                viewModel.continueToNextLevel()
            }
            .transition(.opacity.combined(with: .scale))
            .animation(AnimationSprings.gentle, value: viewModel.showingLevelComplete)
        }
    }
    
    @ViewBuilder
    private var confettiOverlay: some View {
        ConfettiView(trigger: viewModel.showConfetti)
    }
    
    @ViewBuilder
    private var achievementToastOverlay: some View {
        if showAchievementToast, let achievement = achievementManager.newlyUnlockedAchievement {
            VStack {
                AchievementUnlockedToast(achievement: achievement)
                    .transition(.move(edge: .top).combined(with: .opacity))
                Spacer()
            }
            .padding(.top, 60)
            .animation(.spring(), value: showAchievementToast)
        }
    }
}

// MARK: - Word Tap Environment Key

private struct WordTapKey: EnvironmentKey {
    static let defaultValue: (String) -> Void = { _ in }
}

extension EnvironmentValues {
    var onWordTapped: (String) -> Void {
        get { self[WordTapKey.self] }
        set { self[WordTapKey.self] = newValue }
    }
}

#Preview {
    ContentView()
}
