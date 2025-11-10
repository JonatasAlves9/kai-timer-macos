#!/bin/bash

# Configuration
APP_NAME="kai"
DMG_NAME="KAI-Pomodoro"
APP_PATH="$HOME/Library/Developer/Xcode/DerivedData/kai-azvjojpdivaydrdngdwmnhbpsiok/Build/Products/Release/kai.app"
DMG_DIR="./dmg-build"
DMG_TEMP="${DMG_NAME}-temp.dmg"
DMG_FINAL="${DMG_NAME}.dmg"
VOLUME_NAME="KAI Pomodoro"

# Clean up any previous builds
rm -rf "${DMG_DIR}"
rm -f "${DMG_TEMP}"
rm -f "${DMG_FINAL}"

# Create directory structure
mkdir -p "${DMG_DIR}"

# Copy app to DMG directory
echo "Copying app..."
cp -R "${APP_PATH}" "${DMG_DIR}/"

# Create symlink to Applications folder
echo "Creating Applications symlink..."
ln -s /Applications "${DMG_DIR}/Applications"

# Create temporary DMG
echo "Creating temporary DMG..."
hdiutil create -srcfolder "${DMG_DIR}" -volname "${VOLUME_NAME}" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size 100m "${DMG_TEMP}"

# Mount the temporary DMG
echo "Mounting temporary DMG..."
MOUNT_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_TEMP}")
MOUNT_DIR=$(echo "${MOUNT_OUTPUT}" | grep -o '/Volumes/.*' | head -n 1)

echo "Mounted at: ${MOUNT_DIR}"

# Wait for mount to complete
sleep 3

# Verify mount succeeded
if [ -z "${MOUNT_DIR}" ] || [ ! -d "${MOUNT_DIR}" ]; then
    echo "Error: Failed to mount DMG"
    exit 1
fi

# Configure Finder view settings using AppleScript
echo "Configuring Finder view..."
osascript <<EOT
tell application "Finder"
    tell disk "${VOLUME_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 920, 440}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set position of item "${APP_NAME}.app" of container window to {140, 180}
        set position of item "Applications" of container window to {380, 180}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOT

# Wait for Finder to finish
sleep 2

# Unmount the temporary DMG
echo "Unmounting temporary DMG..."
hdiutil detach "${MOUNT_DIR}" || hdiutil detach "/Volumes/${VOLUME_NAME}"

# Wait for unmount
sleep 2

# Convert to compressed final DMG
echo "Creating final compressed DMG..."
hdiutil convert "${DMG_TEMP}" -format UDZO -imagekey zlib-level=9 -o "${DMG_FINAL}"

# Clean up
echo "Cleaning up..."
rm -f "${DMG_TEMP}"
rm -rf "${DMG_DIR}"

echo "DMG created successfully: ${DMG_FINAL}"
ls -lh "${DMG_FINAL}"
