import Foundation
import CoreGraphics

/// Represents a letter in the wheel
struct WheelLetter: Identifiable, Equatable {
    let id = UUID()
    let character: Character
    var isSelected: Bool = false
    var position: CGPoint = .zero

    init(character: Character) {
        self.character = character
    }
}
