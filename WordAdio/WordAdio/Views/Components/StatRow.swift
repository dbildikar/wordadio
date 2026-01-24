import SwiftUI

/// A row displaying a stat with icon, label, and value
struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(label)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        StatRow(icon: "checkmark.circle.fill", label: "Words Found", value: "6", color: .green)
        StatRow(icon: "bitcoinsign.circle.fill", label: "Coins Earned", value: "+42", color: .yellow)
        StatRow(icon: "trophy.fill", label: "Completion Bonus", value: "+25", color: .orange)
    }
    .padding()
}
