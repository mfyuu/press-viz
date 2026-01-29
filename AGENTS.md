# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PressViz is a native macOS application built with SwiftUI for visualizing keyboard presses.

## Tech Stack

- **Language**: Swift 5.0
- **UI Framework**: SwiftUI
- **Platform**: macOS 26.2+
- **Build System**: Xcode

## Build Commands

```bash
# Build the project
xcodebuild -project PressViz.xcodeproj -scheme PressViz -configuration Debug build

# Build for release
xcodebuild -project PressViz.xcodeproj -scheme PressViz -configuration Release build

# Run tests (when available)
xcodebuild -project PressViz.xcodeproj -scheme PressViz test

# Clean build
xcodebuild -project PressViz.xcodeproj -scheme PressViz clean
```

## Architecture

Standard SwiftUI app structure:
- `PressVizApp.swift` - App entry point using `@main` attribute with `WindowGroup` scene
- `ContentView.swift` - Main view component
- `Assets.xcassets/` - Image and color assets

## Key Configuration

- App Sandbox: Enabled
- Bundle Identifier: `com.mfyuu.PressViz`
- Swift Concurrency: Full support with MainActor default isolation
- User Selected Files: Read-only access

## Swift/SwiftUI Guidelines

- Use `@MainActor` for UI-related code (project default isolation is MainActor)
- Prefer `@State`, `@Binding`, `@StateObject`, `@ObservedObject` appropriately for state management
- Use `async/await` for asynchronous operations
- Follow SwiftUI's declarative patterns
