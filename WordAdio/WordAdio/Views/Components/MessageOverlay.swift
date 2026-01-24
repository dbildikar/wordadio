import SwiftUI

/// Overlay for displaying game messages (success, error, info)
struct MessageOverlay: View {
    let message: String
    let type: MessageType

    var body: some View {
        VStack {
            HStack(spacing: 6) {
                Image(systemName: type == .success ? "checkmark.circle.fill" : type == .error ? "xmark.circle.fill" : "info.circle.fill")
                    .font(.subheadline)
                Text(message)
                    .font(Typography.messageText)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(type.color.opacity(0.9))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 8, y: 2)
            )
            
            Spacer()
        }
        .padding(.top, 8)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
        MessageOverlay(message: "+6 coins!", type: .success)
    }
}
