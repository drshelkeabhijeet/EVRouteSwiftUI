#!/bin/bash

# Create a simple app icon using ImageMagick or sips (built-in macOS tool)
# This creates a 1024x1024 PNG with EV text

OUTPUT_DIR="Assets.xcassets/AppIcon.appiconset"
OUTPUT_FILE="$OUTPUT_DIR/AppIcon.png"

# Create icon using macOS built-in sips and other tools
# First, let's create a simple colored square using printf and convert to image

# Method 1: Create using Swift (most reliable on macOS)
cat > temp_icon_generator.swift << 'EOF'
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

func createAppIcon() {
    let size: CGFloat = 1024
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    guard let context = CGContext(
        data: nil,
        width: Int(size),
        height: Int(size),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        print("Failed to create context")
        return
    }

    // Fill with gradient green background
    context.setFillColor(red: 0.0, green: 0.7, blue: 0.4, alpha: 1.0)
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))

    // Draw white circle
    context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    let inset: CGFloat = 150
    context.fillEllipse(in: CGRect(x: inset, y: inset,
                                   width: size - inset * 2,
                                   height: size - inset * 2))

    // Draw EV text (simplified - just rectangles forming letters)
    context.setFillColor(red: 0.0, green: 0.6, blue: 0.3, alpha: 1.0)

    // E
    context.fill(CGRect(x: 300, y: 350, width: 50, height: 200)) // vertical
    context.fill(CGRect(x: 300, y: 350, width: 120, height: 40)) // top horizontal
    context.fill(CGRect(x: 300, y: 440, width: 100, height: 40)) // middle
    context.fill(CGRect(x: 300, y: 530, width: 120, height: 40)) // bottom

    // V
    context.fill(CGRect(x: 500, y: 350, width: 50, height: 180)) // left diagonal
    context.fill(CGRect(x: 620, y: 350, width: 50, height: 180)) // right diagonal
    context.fill(CGRect(x: 550, y: 480, width: 70, height: 70)) // bottom point

    // Lightning bolt in the middle bottom
    context.setFillColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
    context.fill(CGRect(x: 480, y: 600, width: 60, height: 150))

    // Create image from context
    guard let cgImage = context.makeImage() else {
        print("Failed to create image")
        return
    }

    // Save as PNG
    let url = URL(fileURLWithPath: "Assets.xcassets/AppIcon.appiconset/AppIcon.png")

    if let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) {
        CGImageDestinationAddImage(destination, cgImage, nil)
        if CGImageDestinationFinalize(destination) {
            print("Icon saved successfully to AppIcon.png")
        } else {
            print("Failed to save icon")
        }
    }
}

createAppIcon()
EOF

# Compile and run the Swift script
swiftc temp_icon_generator.swift -o temp_icon_generator
./temp_icon_generator

# Clean up
rm -f temp_icon_generator temp_icon_generator.swift

echo "App icon has been created at $OUTPUT_FILE"