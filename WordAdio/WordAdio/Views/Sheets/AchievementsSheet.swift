import SwiftUI

/// Sheet displaying all achievements and progress
struct AchievementsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var achievementManager = AchievementManager.shared
    @ObservedObject var gameCenterManager = GameCenterManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats summary
                    statsSummary
                    
                    // Leaderboard button
                    leaderboardButton
                    
                    // Achievements by category
                    ForEach(Achievement.Category.allCases, id: \.self) { category in
                        achievementSection(for: category)
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
            }
        }
        .sheet(isPresented: $gameCenterManager.showLeaderboard) {
            GameCenterLeaderboardView()
        }
        .onAppear {
            gameCenterManager.checkAuthStatus()
        }
    }
    
    // MARK: - Stats Summary
    
    private var statsSummary: some View {
        VStack(spacing: 16) {
            HStack {
                Text("\(achievementManager.unlockedCount)/\(achievementManager.totalCount)")
                    .font(.title.bold())
                    .foregroundStyle(AppColors.primaryGradient)
                Text("Unlocked")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.primaryGradient)
                        .frame(width: geo.size.width * CGFloat(achievementManager.unlockedCount) / CGFloat(achievementManager.totalCount))
                }
            }
            .frame(height: 12)
            
            // Quick stats
            HStack(spacing: 20) {
                StatBadge(icon: "flag.fill", value: "\(achievementManager.stats.levelsCompleted)", label: "Levels")
                StatBadge(icon: "textformat", value: "\(achievementManager.stats.totalWordsFound)", label: "Words")
                StatBadge(icon: "gift.fill", value: "\(achievementManager.stats.bonusWordsFound)", label: "Bonus")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Leaderboard Button
    
    private var leaderboardButton: some View {
        VStack(spacing: 8) {
            if gameCenterManager.isAuthenticated {
                // Authenticated - show leaderboard button
                Button(action: { gameCenterManager.presentLeaderboard() }) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundStyle(AppColors.coinGradient)
                        
                        VStack(alignment: .leading) {
                            Text("Leaderboard")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("View global rankings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
            } else {
                // Not authenticated - show sign-in prompt
                Button(action: { gameCenterManager.openGameCenterSettings() }) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading) {
                            Text("Leaderboard")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Sign in to Game Center to compete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.forward.app")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
        }
    }
    
    // MARK: - Achievement Section
    
    private func achievementSection(for category: Achievement.Category) -> some View {
        let categoryAchievements = achievementManager.achievements.filter { $0.category == category }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text(category.rawValue)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            ForEach(categoryAchievements) { achievement in
                AchievementRow(
                    achievement: achievement,
                    progress: achievementManager.progress(for: achievement),
                    currentValue: achievementManager.currentValue(for: achievement)
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundColor(.primary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    let progress: Double
    let currentValue: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? AppColors.primaryGradient : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(achievement.isUnlocked ? .white : .gray)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name)
                    .font(.subheadline.bold())
                    .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !achievement.isUnlocked {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.primaryGradient)
                                .frame(width: geo.size.width * progress)
                        }
                    }
                    .frame(height: 6)
                    
                    Text("\(currentValue)/\(achievement.requirement)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Checkmark for unlocked
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(achievement.isUnlocked ? Color.green.opacity(0.1) : Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

// MARK: - Achievement Unlocked Toast

struct AchievementUnlockedToast: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryGradient)
                    .frame(width: 44, height: 44)
                
                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked!")
                    .font(.caption.bold())
                    .foregroundColor(.yellow)
                
                Text(achievement.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
        )
        .padding(.horizontal)
    }
}

#Preview {
    AchievementsSheet()
}
