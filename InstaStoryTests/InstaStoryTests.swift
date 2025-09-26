//
//  InstaStoryTests.swift
//  InstaStoryTests
//
//  Created by Isaac on 09/26/25.
//

import Testing
import SwiftUI
@testable import InstaStory

struct InstaStoryTests {

    // MARK: - StoryTimer Tests


    @Test @MainActor func storyTimerNextStoryNavigation() {
        let timer = StoryTimer(items: 4, duration: 10.0)

        timer.nextStory()
        #expect(timer.currentStoryIndex == 1)

        timer.nextStory()
        #expect(timer.currentStoryIndex == 2)

        timer.nextStory()
        #expect(timer.currentStoryIndex == 3)

        // At last story, should enter dismissing state
        timer.nextStory()
        #expect(timer.state == .dismissing)
        #expect(timer.currentStoryIndex == 3)
    }

    @Test @MainActor func storyTimerPreviousStoryNavigation() {
        let timer = StoryTimer(items: 4, duration: 10.0)

        // Move to second story first
        timer.nextStory()
        timer.nextStory()
        #expect(timer.currentStoryIndex == 2)

        timer.previousStory()
        #expect(timer.currentStoryIndex == 1)

        timer.previousStory()
        #expect(timer.currentStoryIndex == 0)

        // Should not go below 0
        timer.previousStory()
        #expect(timer.currentStoryIndex == 0)
    }

    @Test @MainActor func storyTimerJumpToStory() {
        let timer = StoryTimer(items: 4, duration: 10.0)

        timer.jumpToStory(2)
        #expect(timer.currentStoryIndex == 2)

        // Invalid indices should be ignored
        timer.jumpToStory(10)
        #expect(timer.currentStoryIndex == 2)

        timer.jumpToStory(-1)
        #expect(timer.currentStoryIndex == 2)
    }

    @Test @MainActor func storyTimerStateTransitions() async throws {
        let timer = StoryTimer(items: 4, duration: 1.0)

        timer.start()
        #expect(timer.state == .entering)

        // Wait for async state change
        try await Task.sleep(nanoseconds: 150_000_000)
        #expect(timer.state == .playing)

        timer.pause()
        #expect(timer.state == .pausedByHold)

        timer.resume()
        #expect(timer.state == .playing)

        timer.cancel()
        #expect(timer.state == .idle)
    }

    @Test @MainActor func storyTimerAdvanceFunction() {
        let timer = StoryTimer(items: 4, duration: 10.0)

        // Move to middle position
        timer.nextStory()
        timer.nextStory()
        #expect(timer.currentStoryIndex == 2)

        // Test backward advance
        timer.advance(by: -1)
        #expect(timer.currentStoryIndex == 1)

        // Test multiple backward advance
        timer.advance(by: -2)
        #expect(timer.currentStoryIndex == 0)
    }

    // MARK: - Acceptance Tests

    @Test @MainActor func storyProgressionAcceptance() async throws {
        let timer = StoryTimer(items: 4, duration: 1.0)

        // Start stories
        timer.start()
        try await Task.sleep(nanoseconds: 150_000_000)
        #expect(timer.state == .playing)

        // Auto-progression after duration
        try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
        #expect(timer.currentStoryIndex >= 1, "Story should auto-advance")

        timer.cancel()
    }

    @Test @MainActor func userNavigationAcceptance() {
        let timer = StoryTimer(items: 4, duration: 15.0)

        // Forward navigation
        timer.advance(by: 1)
        #expect(timer.currentStoryIndex == 1, "Forward navigation should work")

        timer.advance(by: 1)
        #expect(timer.currentStoryIndex == 2, "Multiple forward navigation should work")

        // Backward navigation
        timer.advance(by: -1)
        #expect(timer.currentStoryIndex == 1, "Backward navigation should work")

        // Jump to specific story
        timer.jumpToStory(3)
        #expect(timer.currentStoryIndex == 3, "Direct jump should work")

        // Multiple advances
        timer.advance(by: -2)
        #expect(timer.currentStoryIndex == 1, "Multiple backward advance should work")
    }

    @Test @MainActor func pauseResumeAcceptance() async throws {
        let timer = StoryTimer(items: 4, duration: 1.0)

        timer.start()
        try await Task.sleep(nanoseconds: 150_000_000)

        // Pause should stop progression
        timer.pause()
        let pausedIndex = timer.currentStoryIndex
        try await Task.sleep(nanoseconds: 500_000_000)
        #expect(timer.currentStoryIndex == pausedIndex, "Story should not advance when paused")

        // Resume should continue
        timer.resume()
        #expect(timer.state == .playing, "Timer should resume playing")

        timer.cancel()
    }

    // MARK: - Performance Tests

    @Test @MainActor func rapidNavigationPerformance() {
        let timer = StoryTimer(items: 10, duration: 5.0)

        // Rapid navigation shouldn't crash or corrupt state
        for _ in 0..<50 {
            timer.nextStory()
            timer.previousStory()
            timer.jumpToStory(3)
            timer.advance(by: 1)
            timer.advance(by: -1)
        }

        #expect(timer.currentStoryIndex >= 0, "Index should remain valid")
        #expect(timer.currentStoryIndex < 10, "Index should stay within bounds")
    }

    @Test @MainActor func storyCompletionAcceptance() {
        let timer = StoryTimer(items: 3, duration: 5.0)

        // Navigate to last story
        timer.jumpToStory(2)
        #expect(timer.currentStoryIndex == 2)

        // Advancing past last story should trigger dismissing
        timer.nextStory()
        #expect(timer.state == .dismissing, "Should enter dismissing state after last story")
    }

}
