# App Icon Generation

The app icon has been designed in `AppIconGenerator.swift`. To generate the actual icon images:

## Option 1: Use Xcode's Icon Generator
1. Open the project in Xcode
2. Run the app on a simulator
3. Use the AppIconView in a preview or temporary view
4. Take screenshots at different sizes
5. Add them to `Assets.xcassets/AppIcon.appiconset/`

## Option 2: Export Programmatically
You can create a script to export the icon at different sizes using SwiftUI's ImageRenderer (iOS 16+).

## Required Icon Sizes:
- 20x20 @2x, @3x (iPhone)
- 29x29 @2x, @3x (iPhone)
- 40x40 @2x, @3x (iPhone)
- 60x60 @2x, @3x (iPhone)
- 20x20 @1x, @2x (iPad)
- 29x29 @1x, @2x (iPad)
- 40x40 @1x, @2x (iPad)
- 76x76 @1x, @2x (iPad)
- 83.5x83.5 @2x (iPad Pro)
- 1024x1024 @1x (App Store)

The icon design features:
- Vibrant blue-to-purple-to-pink gradient background
- Bold white "W" letter (for WordAdio)
- Decorative circles and rings
- Modern, rounded design
