# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

InstaStory is a SwiftUI application that recreates Instagram-style stories with automatic progression and user interaction controls. The app displays a series of images in fullscreen with progress indicators and touch-based navigation.

## Architecture

### Core Components

- **ContentView.swift**: Main story display interface with image rendering, progress bars, and gesture handling for navigation/pause
- **StoryTimer.swift**: ObservableObject managing story progression timing, pause/resume functionality, and automatic advancement
- **LoadingRectangle.swift**: Custom SwiftUI view for displaying progress bars above stories
- **InstaStoryApp.swift**: App entry point using SwiftUI App structure

### Key Patterns

- **MVVM Architecture**: Uses `@ObservedObject` pattern with `StoryTimer` as the view model
- **Timer-based Progress**: Uses `Timer.scheduledTimer` with 0.01 second intervals for smooth progress animation
- **Gesture Recognition**: Left/right tap areas for navigation, long press for pause/resume
- **State Management**: Published properties in `StoryTimer` drive UI updates through Combine

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project InstaStory.xcodeproj -scheme InstaStory build

# Run in simulator (requires Xcode)
open InstaStory.xcodeproj
# Use Xcode's run button or Cmd+R

# Build for device
xcodebuild -project InstaStory.xcodeproj -scheme InstaStory -destination 'generic/platform=iOS'
```

### Testing
```bash
# Run tests
xcodebuild test -project InstaStory.xcodeproj -scheme InstaStory -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Project Structure

- `InstaStory/`: Main source directory containing all Swift files
- `InstaStory.xcodeproj/`: Xcode project configuration
- `Assets.xcassets/`: Image and asset catalog (contains story images: image01-image04)

## Development Notes

- Story images are referenced by name in `ContentView.swift` (`imageNames` array) and must exist in `Assets.xcassets`
- Timer precision is set to 0.01 seconds for smooth progress bar animation
- Default story duration is 5 seconds per story (configurable in `StoryTimer` init)
- Gesture areas are split 50/50 for previous/next story navigation
- Long press anywhere pauses/resumes the timer