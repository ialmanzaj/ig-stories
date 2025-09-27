//
//  StoriesScreen.swift
//  InstaStory
//
//  Created by Isaac on 09/26/25.
//

import SwiftUI

// MARK: - Progress Bar Component
/// Isolated progress bar component to prevent unnecessary re-renders of the main story view
/// Only this component re-renders every 10ms when storyTimer.progress updates
private struct ProgressBarRow: View {
  @ObservedObject var storyTimer: StoryTimer
  let imageNames: [String]

  var body: some View {
    HStack(alignment: .center, spacing: 4) {
      ForEach(0..<imageNames.count, id: \.self) { x in
        LoadingRectangle(
          progress: min(max(CGFloat(storyTimer.progress) - CGFloat(x), 0.0), 1.0),
          storyIndex: x
        )
        .frame(height: 4, alignment: .leading)
        .animation(.none, value: storyTimer.progress)
        .accessibilityIdentifier("ProgressBar\(x)")
        .onTapGesture { storyTimer.jumpToStory(x) }
      }
    }
    .accessibilityIdentifier("ProgressBarContainer")
  }
}

private struct HeaderBar: View {
  let title: String
  let onBack: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Button(action: onBack) {
        Image(systemName: "chevron.left")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(.white)
          .frame(width: 36, height: 36)
          .background(.white.opacity(0))
          .clipShape(Circle())
          .contentShape(Circle())
      }
      Text(title)
        .font(.system(size: 22, weight: .semibold))
        .foregroundStyle(.white)
      Spacer()
    }
  }
}

// MARK: - Story Content View
/// Instagram-style story viewer with automatic progression, hold-to-pause, and tap navigation
/// Implements the complete Instagram Stories experience with precise gesture handling
struct StoriesScreen: View {
  @Environment(\.dismiss) private var dismiss
  /// Array of image names to display in the story sequence
  /// These images must exist in the Assets.xcassets catalog
  var imageNames: [String] = ["image01", "image02", "image03", "image04"]

  /// Story timer managing progression, pause/resume, and state
  /// ObservableObject pattern ensures UI updates when timer state changes
  @ObservedObject var storyTimer: StoryTimer = StoryTimer(items: 4, duration: 15.0)


  var body: some View {
    // MARK: - Navigation Structure
    /// Navigation stack containing a demo link to stock prices view
    /// This demonstrates navigation integration while maintaining story functionality
    //NavigationStack {
      // MARK: - Story Display Container
      /// GeometryReader provides screen dimensions for precise layout calculations
      /// Critical for implementing Instagram's 33%/67% tap zone specification
      GeometryReader { geometry in
        // MARK: - Local Geometry Calculations
        /// Compute layout values locally to eliminate render loops
        let geometrywidth = geometry.size.width
        let usableWidth = geometrywidth - geometry.safeAreaInsets.leading - geometry.safeAreaInsets.trailing
        let leftZoneWidth = usableWidth * 0.33
        let rightZoneWidth = usableWidth * 0.67
        let headerTop = geometry.safeAreaInsets.top + 8
        let zonesTop = headerTop + 64  // headerHeight constant

        ZStack(alignment: .top) {
          // MARK: - Main Story Image
          /// Displays the current story image based on timer progress
          /// Uses safe array access to prevent crashes on invalid indices
          /// Falls back to last image if index calculation fails
          Image(imageNames[safe: Int(storyTimer.progress)] ?? imageNames.last!)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: geometrywidth, height: nil, alignment: .center)
            .clipped()  // Crop overflow content
            .ignoresSafeArea()  // Full-screen immersive experience
            .accessibilityIdentifier("StoryImage")  // For UI testing
            
         
          VStack(spacing: 12) {
            // MARK: - Custom Header (back + title)
            HeaderBar(title: "Stock Prices", onBack: { dismiss() })
        
            // MARK: - Progress Bar Section
            ProgressBarRow(storyTimer: storyTimer, imageNames: imageNames)
          }
          .padding()
          .zIndex(2) // keep above everything


          // MARK: - Navigation Zones
          /// Invisible tap zones implementing Instagram's 33%/67% navigation specification
          /// Left zone (33%) goes to previous story, right zone (67%) goes to next story
          HStack(alignment: .center, spacing: 0) {
            /// LEFT NAVIGATION ZONE (33% of screen width)
            /// Tap here to go to previous story
            Rectangle()
              .foregroundColor(.clear)  // Invisible but tappable
              .contentShape(Rectangle())  // Ensure tap detection on clear rectangle
              .frame(maxWidth: leftZoneWidth)
              .accessibilityIdentifier("LeftNavigationZone")  // For UI testing (coordinate-based)
              .onTapGesture {
                /// State guard: prevent navigation during hold-to-pause
                guard storyTimer.state != .pausedByHold else { return }
                storyTimer.advance(by: -1)  // Go to previous story
              }

            /// RIGHT NAVIGATION ZONE (67% of screen width)
            /// Tap here to go to next story - larger zone matches Instagram UX
            Rectangle()
              .foregroundColor(.clear)  // Invisible but tappable
              .contentShape(Rectangle())  // Ensure tap detection on clear rectangle
              .frame(maxWidth: rightZoneWidth)
              .accessibilityIdentifier("RightNavigationZone")  // For UI testing (coordinate-based)
              .onTapGesture {
                /// State guard: prevent navigation during hold-to-pause
                guard storyTimer.state != .pausedByHold else { return }
                storyTimer.advance(by: 1)  // Go to next story
              }
          }
          /// Apply safe area padding to navigation zones
          .padding(.leading, geometry.safeAreaInsets.leading)
          .padding(.trailing, geometry.safeAreaInsets.trailing)
          .padding(.top, zonesTop)
          .accessibilityIdentifier("NavigationZones")

          // MARK: - Hold-to-Pause Gesture
          /// Instagram-style hold-to-pause functionality using DragGesture
          /// This was the breakthrough solution after testing multiple gesture approaches
          .simultaneousGesture(
            /// DragGesture(minimumDistance: 0) detects immediate touch down/up
            /// Unlike LongPressGesture, this reliably tracks finger release
            DragGesture(minimumDistance: 0)
              .onChanged { _ in
                /// Touch detected - pause if currently playing
                /// Only pause from playing state to prevent unwanted state changes
                if storyTimer.state == .playing {
                  storyTimer.pause()
                }
              }
              .onEnded { _ in
                /// Touch released - resume if paused by hold
                /// State check ensures we only resume holds, not other pause types
                if storyTimer.state == .pausedByHold {
                  storyTimer.resume()
                }
              }
          )
        }
        .accessibilityIdentifier("StoryView")
      }
      // MARK: - Lifecycle Management
      .onAppear { storyTimer.start() }  // Start story progression when view appears
      .onDisappear { storyTimer.cancel() }  // Clean up timer when view disappears
      .toolbar(.hidden, for: .navigationBar)
      .statusBarHidden(false)
    }
  //}
}
// MARK: - Safe Array Access Extension
/// Provides safe array access to prevent index out of bounds crashes
/// Returns nil if index is invalid instead of crashing
extension Array {
  subscript(safe index: Int) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}
// --- safe index helper ---
extension Collection {
  subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}

// MARK: - SwiftUI Preview
/// Preview provider for Xcode canvas development and testing
#Preview {
    StoriesScreen()
}
