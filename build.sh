#!/bin/bash

# Exit immediately if any command fails
set -e

echo "🚀 Starting build process for NetworkMonitor..."

# 1. Build the executable using Swift Package Manager
echo "📦 Compiling Swift Package (Release mode)..."
swift build -c release

# 2. Create the .app bundle directory structure
echo "📂 Creating App Bundle structure..."
APP_DIR="build/NetworkMonitor.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

# Clean up previous builds
rm -rf build/
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 3. Copy the compiled binary to the bundle
echo "💾 Copying binary..."
cp .build/release/NetworkMonitor "$MACOS_DIR/NetworkMonitor"

# 4. Generate the Info.plist
echo "📝 Generating Info.plist..."
cat <<EOF > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>NetworkMonitor</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.abuzar.mac-network-monitor</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>NetworkMonitor</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.0</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# 5. Generate the Apple Icon Image (.icns) from our PNG
if [ -f "app_icon.png" ]; then
    echo "🎨 Generating native macOS AppIcon (.icns) from app_icon.png..."
    ICONSET_DIR="NetworkMonitor.iconset"
    mkdir -p "$ICONSET_DIR"
    
    # Resize PNG into standard Apple iconset sizes
    sips -s format png -z 16 16     app_icon.png --out "$ICONSET_DIR/icon_16x16.png" > /dev/null 2>&1
    sips -s format png -z 32 32     app_icon.png --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null 2>&1
    sips -s format png -z 32 32     app_icon.png --out "$ICONSET_DIR/icon_32x32.png" > /dev/null 2>&1
    sips -s format png -z 64 64     app_icon.png --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null 2>&1
    sips -s format png -z 128 128   app_icon.png --out "$ICONSET_DIR/icon_128x128.png" > /dev/null 2>&1
    sips -s format png -z 256 256   app_icon.png --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null 2>&1
    sips -s format png -z 256 256   app_icon.png --out "$ICONSET_DIR/icon_256x256.png" > /dev/null 2>&1
    sips -s format png -z 512 512   app_icon.png --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null 2>&1
    sips -s format png -z 512 512   app_icon.png --out "$ICONSET_DIR/icon_512x512.png" > /dev/null 2>&1
    sips -s format png -z 1024 1024 app_icon.png --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null 2>&1
    
    # Convert iconset directory to a single .icns file
    iconutil -c icns "$ICONSET_DIR"
    
    # Move to Resources folder
    mv NetworkMonitor.icns "$RESOURCES_DIR/AppIcon.icns"
    
    # Clean up temporary iconset directory
    rm -rf "$ICONSET_DIR"
    echo "✅ AppIcon.icns generated successfully."
else
    echo "⚠️ app_icon.png not found. Skipping AppIcon.icns generation."
fi

# 6. Apply ad-hoc codesign to run locally on Apple Silicon / Intel Macs
echo "🔑 Applying ad-hoc codesign signature..."
codesign --force --deep --sign - "$APP_DIR"

echo "🎉 Build complete! You can find the app at: build/NetworkMonitor.app"
echo "👉 To launch, run: open build/NetworkMonitor.app"
