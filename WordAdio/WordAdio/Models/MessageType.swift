import SwiftUI

/// Types of messages that can be displayed to the user
enum MessageType {
    case success
    case error
    case info

    var color: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .info:
            return .blue
        }
    }
}
