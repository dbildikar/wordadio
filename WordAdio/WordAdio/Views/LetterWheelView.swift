import SwiftUI

/// Circular letter wheel for word input
/// Supports both touch and mouse interaction for iOS Simulator
struct LetterWheelView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var dragPosition: CGPoint?
    @State private var wheelCenter: CGPoint = .zero
    @State private var lastDragIndex: Int?

    var body: some View {
        GeometryReader { geometry in
            let wheelRadius = calculateWheelRadius(for: geometry.size)
            let letterRadius = LayoutMetrics.letterButtonRadius
            
            ZStack {
                // Wheel background
                wheelBackground(radius: wheelRadius)

                // Connecting line animation between selected letters
                if viewModel.selectedLetterIndices.count > 1 {
                    connectingLines(wheelRadius: wheelRadius)
                }

                // Letter buttons arranged in a circle
                ForEach(Array(viewModel.wheelLetters.enumerated()), id: \.offset) { index, letter in
                    LetterButton(
                        letter: letter,
                        index: index,
                        wheelRadius: wheelRadius,
                        letterRadius: letterRadius,
                        totalLetters: viewModel.wheelLetters.count
                    )
                    .onTapGesture {
                        handleLetterTap(at: index)
                    }
                }

                // Center circle showing current word with glow
                centerWordDisplay(wheelRadius: wheelRadius)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                wheelCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDrag(at: value.location, wheelRadius: wheelRadius)
                    }
                    .onEnded { _ in
                        endDrag()
                    }
            )
        }
    }
    
    // MARK: - Layout Calculations
    
    private func calculateWheelRadius(for size: CGSize) -> CGFloat {
        let letterRadius = LayoutMetrics.letterButtonRadius
        let maxRadius = (min(size.width, size.height) - letterRadius * 2) / 2
        return min(LayoutMetrics.wheelRadius, maxRadius)
    }
    
    // MARK: - Subviews
    
    private func wheelBackground(radius: CGFloat) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: radius * 2, height: radius * 2)
            .overlay(
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            )
    }
    
    private func connectingLines(wheelRadius: CGFloat) -> some View {
        ZStack {
            // Drop shadow for depth
            ConnectingLinePath(
                selectedIndices: viewModel.selectedLetterIndices,
                wheelRadius: wheelRadius,
                totalLetters: viewModel.wheelLetters.count
            )
            .stroke(
                Color.black.opacity(0.3),
                style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round)
            )
            .blur(radius: 3)
            .offset(y: 2)
            
            // Outer glow
            ConnectingLinePath(
                selectedIndices: viewModel.selectedLetterIndices,
                wheelRadius: wheelRadius,
                totalLetters: viewModel.wheelLetters.count
            )
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.4)]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round)
            )
            .blur(radius: 6)
            
            // Main thick line
            ConnectingLinePath(
                selectedIndices: viewModel.selectedLetterIndices,
                wheelRadius: wheelRadius,
                totalLetters: viewModel.wheelLetters.count
            )
            .stroke(
                AppColors.lineGradient,
                style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
            )
            
            // Top highlight for raised effect
            ConnectingLinePath(
                selectedIndices: viewModel.selectedLetterIndices,
                wheelRadius: wheelRadius,
                totalLetters: viewModel.wheelLetters.count
            )
            .stroke(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0.7), location: 0),
                        .init(color: Color.white.opacity(0.2), location: 0.5),
                        .init(color: Color.clear, location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ),
                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
            )
            .animation(AnimationSprings.smooth, value: viewModel.selectedLetterIndices)
        }
    }
    
    private func centerWordDisplay(wheelRadius: CGFloat) -> some View {
        ZStack {
            // Soft glow background
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 5,
                        endRadius: wheelRadius * 0.5
                    )
                )
                .frame(width: wheelRadius * 1.2, height: wheelRadius * 1.2)
            
            VStack(spacing: 4) {
                Text(viewModel.currentWord)
                    .font(Typography.currentWord)
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(width: wheelRadius * 1.2)

                if !viewModel.currentWord.isEmpty {
                    Text("\(viewModel.currentWord.count) letters")
                        .font(Typography.letterCount)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Interaction Handlers

    private func handleLetterTap(at index: Int) {
        if viewModel.wheelLetters[index].isSelected {
            viewModel.deselectLastLetter()
        } else {
            viewModel.selectLetter(at: index)
        }
    }

    private func handleDrag(at location: CGPoint, wheelRadius: CGFloat) {
        dragPosition = location

        guard let letterIndex = findClosestLetter(to: location, wheelRadius: wheelRadius) else { return }
        
        if lastDragIndex == letterIndex {
            return
        }
        
        if let selectedPosition = viewModel.selectedLetterIndices.firstIndex(of: letterIndex) {
            if selectedPosition < viewModel.selectedLetterIndices.count - 1 {
                let countToRemove = viewModel.selectedLetterIndices.count - selectedPosition - 1
                for _ in 0..<countToRemove {
                    viewModel.deselectLastLetter()
                }
            }
        } else {
            viewModel.selectLetter(at: letterIndex)
        }
        
        lastDragIndex = letterIndex
    }

    private func endDrag() {
        dragPosition = nil
        lastDragIndex = nil
        if !viewModel.currentWord.isEmpty {
            viewModel.submitWord()
        }
    }

    private func findClosestLetter(to point: CGPoint, wheelRadius: CGFloat) -> Int? {
        var closestIndex: Int?
        let letterRadius = LayoutMetrics.letterButtonRadius
        var closestDistance: CGFloat = letterRadius * 1.5

        for (index, _) in viewModel.wheelLetters.enumerated() {
            let angle = (2 * .pi / CGFloat(viewModel.wheelLetters.count)) * CGFloat(index) - .pi / 2
            let x = wheelCenter.x + wheelRadius * cos(angle)
            let y = wheelCenter.y + wheelRadius * sin(angle)

            let distance = sqrt(pow(point.x - x, 2) + pow(point.y - y, 2))

            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }

        return closestIndex
    }
}

// MARK: - Letter Button

/// Individual letter button in the wheel
struct LetterButton: View {
    let letter: WheelLetter
    let index: Int
    let wheelRadius: CGFloat
    let letterRadius: CGFloat
    let totalLetters: Int

    private var position: CGPoint {
        let angle = (2 * .pi / CGFloat(totalLetters)) * CGFloat(index) - .pi / 2
        let x = wheelRadius * cos(angle)
        let y = wheelRadius * sin(angle)
        return CGPoint(x: x, y: y)
    }

    var body: some View {
        ZStack {
            // Outer shadow for depth
            Circle()
                .fill(letter.isSelected ? Color.blue : Color.white)
                .frame(width: letterRadius * 2, height: letterRadius * 2)
                .shadow(color: letter.isSelected ? Color.blue.opacity(0.5) : Color.black.opacity(0.3),
                        radius: letter.isSelected ? 6 : 4,
                        x: 2, y: 3)
            
            // Bevel highlight (top-left light)
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(letter.isSelected ? 0.4 : 0.8), location: 0),
                            .init(color: Color.clear, location: 0.5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: letterRadius * 2 - 4, height: letterRadius * 2 - 4)
            
            // Bevel shadow (bottom-right dark)
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.clear, location: 0.5),
                            .init(color: Color.black.opacity(letter.isSelected ? 0.2 : 0.15), location: 1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: letterRadius * 2 - 4, height: letterRadius * 2 - 4)

            // Border
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.6),
                            Color.gray.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: letterRadius * 2, height: letterRadius * 2)

            Text(String(letter.character))
                .font(Typography.letterButton)
                .foregroundColor(letter.isSelected ? .white : .black)
        }
        .offset(x: position.x, y: position.y)
        .scaleEffect(letter.isSelected ? 1.1 : 1.0)
        .animation(AnimationSprings.bouncy, value: letter.isSelected)
    }
}

// MARK: - Connecting Line Path

/// Path for drawing connecting lines between selected letters
struct ConnectingLinePath: Shape {
    let selectedIndices: [Int]
    let wheelRadius: CGFloat
    let totalLetters: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard selectedIndices.count > 1 else { return path }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        var points: [CGPoint] = []
        for index in selectedIndices {
            let angle = (2 * .pi / CGFloat(totalLetters)) * CGFloat(index) - .pi / 2
            let x = center.x + wheelRadius * cos(angle)
            let y = center.y + wheelRadius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        
        for i in 0..<points.count - 1 {
            if i == 0 {
                path.move(to: points[i])
            }
            path.addLine(to: points[i + 1])
        }
        
        return path
    }
}

#Preview {
    LetterWheelView(viewModel: GameViewModel())
        .frame(height: 400)
        .background(Color.gray.opacity(0.05))
}
