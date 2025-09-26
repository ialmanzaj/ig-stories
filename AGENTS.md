# Repository Guidelines

## Project Structure & Module Organization
- `InstaStory/` contains the SwiftUI app: `InstaStoryApp.swift` wires App state, `ContentView.swift` drives the story UI, and helpers like `StoryTimer.swift` and `LoadingRectangle.swift` live alongside assets in `Assets.xcassets`.
- `InstaStoryTests/` hosts end-to-end focused unit tests using the Swift Testing framework; keep new fixtures here and mirror the production file names when possible.
- `InstaStory.xcodeproj` defines the iOS target configuration. Open it in Xcode to inspect schemes, simulator settings, and asset catalogs.

## Build, Test, and Development Commands
- `open InstaStory.xcodeproj` launches Xcode with the configured `InstaStory` scheme.
- `xcodebuild -scheme InstaStory -destination 'platform=iOS Simulator,name=iPhone 15' build` performs a CLI build that matches CI expectations.
- `xcodebuild test -scheme InstaStory -destination 'platform=iOS Simulator,name=iPhone 15'` executes the Swift Testing suite; pair with `-only-testing:InstaStoryTests/StoryTimer` to focus on one group.
- Use Xcode Previews in `ContentView.swift` for quick UI iterations; keep preview-specific code guarded with `#if DEBUG` when needed.

## Coding Style & Naming Conventions
- Follow Swift API Design Guidelines: camelCase for functions/properties, UpperCamelCase for types, snake_case is reserved for test identifiers or raw asset names.
- Indent with four spaces and place braces on the same line as declarations (`struct StoryTimer {`). Keep chained modifiers on new lines for readability, as seen in `ContentView`.
- Prefer lightweight extensions in their own files when they grow beyond a few lines; document non-obvious behavior with concise `///` comments.

## Testing Guidelines
- Tests use the `Testing` framework’s `@Test` attribute and `#expect` assertions. Name tests with an intent-first phrase (`storyTimerStateTransitions`).
- Always verify async flows with `Task.sleep` rather than fixed timers, and cover both navigation and timing edge cases before merging.
- Run the full suite with `xcodebuild test ...` before opening a PR; attach failing seeds or simulator logs if a flake appears.

## Commit & Pull Request Guidelines
- Follow the existing Conventional Commit pattern (`feat:`, `fix:`, `refactor:`). Make messages imperative and scoped (`feat: add pause resume coverage`).
- PRs should state motivation, summarize UI or timer changes, and link any relevant issues. Include simulator screenshots or short clips for visual tweaks and describe test coverage (`xcodebuild test`).
