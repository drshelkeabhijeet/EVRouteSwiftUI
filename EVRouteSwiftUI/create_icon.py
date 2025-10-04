#!/usr/bin/env python3
"""
Creates a simple app icon for EVRouteSwiftUI
Requires: PIL (Pillow) - install with: pip3 install Pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_app_icon():
    # Create a 1024x1024 image with gradient background
    size = 1024
    image = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(image)

    # Create gradient background (green EV theme)
    for y in range(size):
        # Gradient from light green to darker green
        r = int(0 + (20 * y / size))
        g = int(180 - (40 * y / size))
        b = int(100 - (30 * y / size))
        draw.rectangle([(0, y), (size, y+1)], fill=(r, g, b))

    # Draw a white circle for contrast
    circle_margin = 150
    draw.ellipse(
        [(circle_margin, circle_margin),
         (size - circle_margin, size - circle_margin)],
        fill=(255, 255, 255, 255)
    )

    # Draw EV text
    text = "EV"
    # Try to use a system font, fallback to default
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 400)
    except:
        font = ImageFont.load_default()

    # Get text dimensions for centering
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Center the text
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - 100

    # Draw the text in green
    draw.text((x, y), text, fill=(0, 150, 70), font=font)

    # Draw a lightning bolt symbol below (simplified)
    bolt_points = [
        (size//2 - 50, size//2 + 50),
        (size//2 + 30, size//2 + 150),
        (size//2 - 10, size//2 + 150),
        (size//2 + 50, size//2 + 280),
        (size//2 - 30, size//2 + 170),
        (size//2 + 10, size//2 + 170),
    ]
    draw.polygon(bolt_points, fill=(0, 150, 70))

    # Save the icon
    output_path = "Assets.xcassets/AppIcon.appiconset/AppIcon.png"
    image.save(output_path, "PNG")
    print(f"App icon created at: {output_path}")
    return output_path

if __name__ == "__main__":
    create_app_icon()