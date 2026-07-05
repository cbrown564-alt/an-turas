#!/usr/bin/env python3
import os
import json
import subprocess

SOURCE_IMAGE = "/Users/cobro/.gemini/antigravity/brain/b46d2979-d738-4751-b139-b33a7fb1d80a/fainne_variant_inscribed_1783273405408.jpg"
ASSET_CATALOG_DIR = "ios/AnTuras/Assets.xcassets/AppIcon.appiconset"

# Icon dimensions mapping (filename -> size in pixels)
ICON_SIZES = {
    "icon-20@2x.png": 40,
    "icon-20@3x.png": 60,
    "icon-29@2x.png": 58,
    "icon-29@3x.png": 87,
    "icon-40@2x.png": 80,
    "icon-40@3x.png": 120,
    "icon-60@2x.png": 120,
    "icon-60@3x.png": 180,
    "icon-1024.png": 1024
}

CONTENTS_JSON = {
  "images" : [
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "icon-20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "icon-20@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "icon-29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "icon-29@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "icon-40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "icon-40@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "icon-60@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "icon-60@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "1024x1024",
      "idiom" : "ios-marketing",
      "filename" : "icon-1024.png",
      "scale" : "1x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}

def main():
    if not os.path.exists(SOURCE_IMAGE):
        print(f"Error: Source image not found at {SOURCE_IMAGE}")
        return

    # Create destination directory
    os.makedirs(ASSET_CATALOG_DIR, exist_ok=True)
    print(f"Created catalog directory: {ASSET_CATALOG_DIR}")

    # Write Contents.json
    contents_path = os.path.join(ASSET_CATALOG_DIR, "Contents.json")
    with open(contents_path, "w") as f:
        json.dump(CONTENTS_JSON, f, indent=2)
    print(f"Wrote Contents.json")

    # Generate icons using macOS built-in sips tool
    for filename, size in ICON_SIZES.items():
        dest_path = os.path.join(ASSET_CATALOG_DIR, filename)
        print(f"Generating {filename} ({size}x{size}px)...")
        # Run sips: convert to png and scale
        cmd = [
            "sips",
            "-s", "format", "png",
            "--resampleWidth", str(size),
            SOURCE_IMAGE,
            "--out", dest_path
        ]
        result = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        if result.returncode != 0:
            print(f"Failed to generate {filename}: {result.stderr.decode()}")
        else:
            print(f"Successfully generated {filename}")

    print("App icon asset generation complete!")

if __name__ == "__main__":
    main()
