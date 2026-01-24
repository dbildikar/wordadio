#!/bin/bash
# Script to generate app icon from SwiftUI view
# This requires running the app and taking screenshots, or using ImageRenderer

echo "App icon generation instructions:"
echo "1. Open the project in Xcode"
echo "2. Add AppIconView to a preview or temporary view"
echo "3. Take screenshots at required sizes"
echo "4. Add images to Assets.xcassets/AppIcon.appiconset/"
echo ""
echo "Required sizes:"
echo "- 20x20 @2x, @3x (40x40, 60x60)"
echo "- 29x29 @2x, @3x (58x58, 87x87)"
echo "- 40x40 @2x, @3x (80x80, 120x120)"
echo "- 60x60 @2x, @3x (120x120, 180x180)"
echo "- 1024x1024 for App Store"
