//
//  Trapezoid.swift
//  InstaStory
//
//  Created by Isaac on 09/27/25.
//

import SwiftUI
import Combine

// MARK: - Shape Component

/**
 * Trapezoid Shape - Custom SwiftUI Shape for Building Block Animation
 *
 * Purpose: Creates rectangular building blocks for the falling animation effect.
 * Currently configured as a simple rectangle (topInset = 0), but designed to be
 * extensible for future trapezoid variations if needed.
 *
 * Design Decision: Using a custom Shape instead of built-in Rectangle allows for
 * future flexibility to create actual trapezoid shapes or add visual effects
 * specific to the animation blocks.
 */
struct Trapezoid: Shape {
    var topInset: CGFloat

    /// Creates a rectangular path that forms the building block shape
    /// - Parameter r: The rectangle bounds in which to draw the shape
    /// - Returns: A Path defining the block's outline
    func path(in r: CGRect) -> Path {
        var p = Path()
        // Draw a rectangle by connecting the four corners
        // Starting from bottom-left, going clockwise
        p.move(to: CGPoint(x: 0, y: r.maxY))           // Bottom-left
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))   // Bottom-right
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))   // Top-right
        p.addLine(to: CGPoint(x: 0, y: r.minY))        // Top-left
        p.closeSubpath()                               // Close the shape
        return p
    }
}

// MARK: - Configuration Component

/**
 * FallingBlockConfig - Configuration for falling block animation
 *
 * Purpose: Centralizes all animation parameters, timing, and visual settings
 * in a clean, data-focused structure. This separation allows easy tweaking
 * of animation behavior without touching the view logic.
 */
struct FallingBlockConfig {
    /// Number of building blocks in the stack
    let levels: Int = 3

    /// Height of each individual building block in points
    let blockHeight: CGFloat = 72

    /// Distance from bottom of screen to the bottom of the stack
    let landingGap: CGFloat = 120

    /// Duration for each block to fall from top to its landing position
    let fallDuration: Double = 1.0

    /// Brief pause between blocks to create rhythmic timing
    let settlePause: Double = 0.05

    /// Color palette for blocks, ordered from bottom to top of final stack
    /// Uses earthy tones that create visual hierarchy and depth
    let colorsBottomToTop: [Color] = [
        Color(red: 0.357, green: 0.227, blue: 0.122), // Dark brown base - foundation
        Color(red: 0.714, green: 0.514, blue: 0.365), // Tan middle - transition
        Color(red: 0.545, green: 0.588, blue: 0.624)  // Blue-gray top - accent
    ]

    /// Dark background color for contrast with falling blocks
    let backgroundColor: Color = Color(red: 0.09, green: 0.06, blue: 0.15)

    /// Linear animation without easing for consistent falling speed
    var fallAnimation: Animation {
        .linear(duration: fallDuration)
    }
}

// MARK: - State Management Component

/**
 * FallingBlockState - Observable state management for falling block animation
 *
 * Purpose: Manages all animation state in a centralized, observable way.
 * Separates state management from view logic, making the animation
 * easier to test and reason about.
 */
final class FallingBlockState: ObservableObject {
    private let config = FallingBlockConfig()

    /// Visibility state for each fixed slot position (false = invisible, true = visible)
    @Published var slotVisible = Array(repeating: false, count: 3)

    /// Whether flying block is visible during animation
    @Published var flyVisible: Bool = false

    /// Current color of the flying block
    @Published var flyColor: Color = .clear

    /// Y position of flying block center
    @Published var flyCenterY: CGFloat = -2000

    /// Starts the complete falling animation sequence
    /// - Parameter slotPositions: Y coordinates for each slot position
    @MainActor
    func startAnimation(slotPositions: [CGFloat]) async {
        // Reset all slots to invisible
        slotVisible = Array(repeating: false, count: config.levels)

        // Sequential falling animation implementing LIFO stacking
        for i in 0..<config.levels {
            await dropBlock(to: i, at: slotPositions[i])
        }
    }

    /// Animates a single block drop to a specific slot
    /// - Parameters:
    ///   - targetSlot: Index of the target slot (0 = bottom, 2 = top)
    ///   - position: Y coordinate for the target position
    @MainActor
    private func dropBlock(to targetSlot: Int, at position: CGFloat) async {
        // Setup flying block for this drop
        flyColor = config.colorsBottomToTop[targetSlot]
        flyCenterY = -config.blockHeight  // Start above screen
        flyVisible = true

        // Animate the fall using linear motion
        withAnimation(config.fallAnimation) {
            flyCenterY = position  // Drop to target position
        }

        // Wait for fall animation to complete
        try? await Task.sleep(nanoseconds: UInt64(config.fallDuration * 1_000_000_000))

        // Instant transition: hide flying block, show fixed slot
        var transaction = Transaction()
        transaction.disablesAnimations = true  // Disable animations for instant transition
        withTransaction(transaction) {
            slotVisible[targetSlot] = true  // Show block in final position
            flyVisible = false              // Hide flying block
        }

        // Brief pause before next block for rhythm
        try? await Task.sleep(nanoseconds: UInt64(config.settlePause * 1_000_000_000))
    }
}

// MARK: - Main Animation View Component

/**
 * Phase1NoOverlapLIFOView - Main falling block animation view
 *
 * ANIMATION CONCEPT:
 * Creates a satisfying falling block animation where blocks drop from above and stack
 * using LIFO (Last In, First Out) ordering - the last block to fall lands on top.
 *
 * VISUAL DESIGN:
 * - 3 building blocks fall sequentially from off-screen
 * - Each block has a distinct earthy color (brown base, tan middle, blue-gray top)
 * - Blocks stack vertically with precise positioning
 * - Clean, linear animation without bouncing or overlapping
 *
 * TECHNICAL APPROACH:
 * - Uses fixed invisible "slots" that define final positions
 * - Single flying block animates between positions using absolute coordinates
 * - Implements opacity-based state transitions for smooth visual handoff
 * - No collision detection needed due to sequential timing
 */
struct Phase1NoOverlapLIFOView: View {
    private let config = FallingBlockConfig()
    @StateObject private var animationState = FallingBlockState()
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height

            // MARK: - Position Calculator Component

            /// Calculate the center Y coordinates for each slot position
            /// Index 0 = bottom of stack, Index 2 = top of stack
            /// This creates the precise landing positions for each falling block
            let slotPositions: [CGFloat] = (0..<config.levels).map { slotIndex in
                let stackBottomY = screenHeight - config.landingGap
                // Each block is positioned above the previous one by blockHeight
                return stackBottomY - (CGFloat(slotIndex) + 0.5) * config.blockHeight
            }

            ZStack {
                // MARK: - Fixed Slot Renderer Component

                /// Fixed slots that define the final resting positions
                /// These are invisible until a block "lands" and becomes visible
                /// Purpose: Eliminates overlapping and ensures consistent positioning
                ForEach(0..<config.levels, id: \.self) { slotIndex in
                    Trapezoid(topInset: 0)
                        .fill(config.colorsBottomToTop[slotIndex])
                        .frame(width: screenWidth, height: config.blockHeight)
                        .position(x: screenWidth / 2, y: slotPositions[slotIndex])
                        .opacity(animationState.slotVisible[slotIndex] ? 1 : 0)
                }

                // MARK: - Flying Block Renderer Component

                /// Single animated block that moves between positions
                /// This creates the falling animation effect by transitioning from
                /// off-screen to each slot position sequentially
                Trapezoid(topInset: 0)
                    .fill(animationState.flyColor)
                    .frame(width: screenWidth, height: config.blockHeight)
                    .position(x: screenWidth / 2, y: animationState.flyCenterY)
                    .opacity(animationState.flyVisible ? 1 : 0)
            }
            .background(config.backgroundColor)
            .ignoresSafeArea()
            .onAppear {
                // MARK: - Animation Trigger Component

                animationTask = Task {
                    /// Trigger the animation sequence using the state manager
                    await animationState.startAnimation(slotPositions: slotPositions)
                }
            }
            .onDisappear {
                animationTask?.cancel()
            }
        }
    }
}

// MARK: - Demo Implementation

/**
 * ContentView - Demo wrapper for the falling block animation
 *
 * Purpose: Provides a simple entry point to showcase the Phase1NoOverlapLIFOView
 * animation in SwiftUI previews and when used as a standalone view.
 *
 * The ignoresSafeArea() modifier ensures the animation fills the entire screen
 * for maximum visual impact, particularly important for the dark background
 * and falling block positioning calculations.
 */
struct ContentView: View {
    var body: some View {
        Phase1NoOverlapLIFOView()
            .ignoresSafeArea()  // Full screen for immersive animation experience
    }
}

// MARK: - SwiftUI Preview

#Preview {
    ContentView()
}
