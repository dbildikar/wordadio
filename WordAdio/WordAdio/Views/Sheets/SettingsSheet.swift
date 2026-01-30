import SwiftUI

/// Settings sheet with privacy policy link and sound/haptic toggles
struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("musicEnabled") private var musicEnabled = true
    @AppStorage("tonesEnabled") private var tonesEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    
    var body: some View {
        NavigationView {
            List {
                // Sound Settings Section
                Section {
                    Toggle(isOn: $musicEnabled) {
                        Label("Background Music", systemImage: "music.note")
                    }
                    .onChange(of: musicEnabled) { _, newValue in
                        SoundManager.shared.setMusicEnabled(newValue)
                        AnalyticsManager.shared.logMusicToggled(enabled: newValue)
                    }
                    
                    Toggle(isOn: $tonesEnabled) {
                        Label("Sound Effects", systemImage: "speaker.wave.2")
                    }
                    .onChange(of: tonesEnabled) { _, newValue in
                        SoundManager.shared.setTonesEnabled(newValue)
                        AnalyticsManager.shared.logSoundEffectsToggled(enabled: newValue)
                    }
                    
                    Toggle(isOn: $hapticsEnabled) {
                        Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
                    }
                    .onChange(of: hapticsEnabled) { _, newValue in
                        HapticManager.shared.setEnabled(newValue)
                        AnalyticsManager.shared.logHapticsToggled(enabled: newValue)
                    }
                } header: {
                    Text("Sound & Feedback")
                }
                
                // About Section
                Section {
                    Link(destination: URL(string: "https://bluefeatherai.com/privacy-policy.html")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                            .foregroundColor(.primary)
                    }
                } header: {
                    Text("About")
                }
                
                // App Info Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("App Info")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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
        .onAppear {
            // Sync UI with current state
            musicEnabled = !SoundManager.shared.isMusicMuted
            tonesEnabled = SoundManager.shared.areTonesEnabled
            hapticsEnabled = HapticManager.shared.isEnabled
            
            // Track settings opened
            AnalyticsManager.shared.logSettingsOpened()
        }
    }
}

#Preview {
    SettingsSheet()
}
