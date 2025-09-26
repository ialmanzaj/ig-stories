//
//  StoryTimer.swift
//  InstaStory
//
//  Created by Isaac on 09/25/25.
//

//
//  StoryTimer.swift
//  InstagramStoryTutorial
//
//  Created by Jean-Marc Boullianne on 4/14/20.
//  Copyright © 2020 TrailingClosure. All rights reserved.
//

import Foundation
import Combine

enum StoryState {
    case idle
    case entering
    case playing
    case pausedByHold
    case buffering
    case error
    case dismissing
}

class StoryTimer: ObservableObject {
    
    @Published var currentStoryIndex: Int = 0
    @Published var progressWithinStory: Double = 0.0
    @Published var state: StoryState = .idle

    private var totalStories: Int
    private var storyDuration: TimeInterval
    private var timer: Timer?
    private var startTime: Date?
    private var pausedTime: TimeInterval = 0
    private var isPaused: Bool = false
    private var advanceQueue: Int = 0
    
    init(items: Int, duration: TimeInterval = 15.0) {
        self.totalStories = items
        self.storyDuration = duration
    }
    
    func start() {
        guard state == .idle else { return }
        state = .entering

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.state = .playing
            self.startStoryTimer()
        }
    }
    
    private func startStoryTimer() {
        // Reset progress for current story
        self.progressWithinStory = 0.0
        self.startTime = Date()
        self.pausedTime = 0
        self.isPaused = false
        
        // Start timer
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            self.updateProgress()
        }
    }
    
    private func updateProgress() {
        guard let startTime = self.startTime, !self.isPaused else { return }

        // Process queued advances
        if self.advanceQueue > 0 {
            let advances = self.advanceQueue
            self.advanceQueue = 0
            DispatchQueue.main.async {
                for _ in 0..<advances {
                    self.nextStory()
                }
            }
            return
        }

        let elapsed = Date().timeIntervalSince(startTime)
        let totalTime = elapsed + self.pausedTime
        let progress = min(totalTime / self.storyDuration, 1.0) // Cap at 1.0

        self.progressWithinStory = progress

        // Only advance to next story if we're not paused and naturally reached the end
        if progress >= 1.0 && !self.isPaused {
            DispatchQueue.main.async {
                self.nextStory()
            }
        }
    }
    
    func pause() {
        guard state == .playing else { return }

        state = .pausedByHold
        self.isPaused = true

        // Capture elapsed time before pausing
        if let startTime = self.startTime {
            let elapsed = Date().timeIntervalSince(startTime)
            self.pausedTime += elapsed
        }

        // Invalidate timer
        self.timer?.invalidate()
        self.timer = nil
    }

    func resume() {
        guard state == .pausedByHold else { return }

        state = .playing
        self.isPaused = false
        // Reset startTime to now, accounting for already elapsed time
        self.startTime = Date()
        // Restart timer
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            self.updateProgress()
        }
    }
    
    func cancel() {
        self.timer?.invalidate()
        self.timer = nil
        state = .idle
    }

    func enterBuffering() {
        guard state == .playing else { return }
        state = .buffering
        // Keep timer running but pause progress
    }

    func exitBuffering() {
        guard state == .buffering else { return }
        state = .playing
        // Resume normal progress
    }

    func enterError() {
        state = .error
        self.timer?.invalidate()
        self.timer = nil
    }

    func enterDismissing() {
        state = .dismissing
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func nextStory() {
        if currentStoryIndex >= totalStories - 1 {
            // At last story - should exit instead of looping
            enterDismissing()
        } else {
            self.currentStoryIndex += 1
            startStoryTimer()
        }
    }
    
    func previousStory() {
        if currentStoryIndex > 0 {
            self.currentStoryIndex -= 1
            startStoryTimer()
        }
        // No-op if at first story as per spec
    }
    
    func advance(by number: Int) {
        if number > 0 {
            // Queue forward advances for rapid tapping
            self.advanceQueue += number
        } else if number < 0 {
            // Moving backward - execute immediately
            for _ in 0..<(-number) {
                self.previousStory()
            }
        }
    }

    func jumpToStory(_ index: Int) {
        guard index >= 0 && index < self.totalStories else { return }
        self.currentStoryIndex = index
        startStoryTimer()
    }
    
    // Computed property to get overall progress for UI
    var progress: Double {
        return Double(self.currentStoryIndex) + self.progressWithinStory
    }
}
