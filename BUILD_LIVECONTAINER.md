# Building for LiveContainer

## What is LiveContainer?

LiveContainer is an iOS app that allows you to inject dylibs into apps without jailbreak, similar to TrollStore but with dynamic library injection support.

## Building the Injectable Dylib

### Method 1: Using Makefile.livecontainer

```bash
# Build with LiveContainer configuration
make -f Makefile.livecontainer clean
make -f Makefile.livecontainer

# The dylib will be at:
# .theos/obj/debug/libDeviceIDSpoofer.dylib
```

### Method 2: Manual Build

```bash
# Clean previous builds
make clean

# Build as library instead of tweak
export THEOS_PACKAGE_SCHEME=rootless
make FINALPACKAGE=1 LIBRARY_NAME=DeviceIDSpoofer

# Or use direct clang commands:
clang -arch arm64 -arch arm64e \
  -dynamiclib \
  -fobjc-arc \
  -framework UIKit \
  -framework Foundation \
  -framework CoreGraphics \
  -o DeviceIDSpoofer.dylib \
  Tweak.x FloatingWindow.m DeviceIDManager.m UIManager.m
```

## Using with LiveContainer

### Step 1: Copy the dylib to your device

```bash
# Via SSH/SCP
scp .theos/obj/debug/libDeviceIDSpoofer.dylib root@YOUR_DEVICE_IP:/tmp/

# Or via Filza/other file manager
# Copy libDeviceIDSpoofer.dylib to a location accessible by LiveContainer
```

### Step 2: Inject into app via LiveContainer

1. Open **LiveContainer** app
2. Select the target app you want to inject into
3. Go to **Tweaks/Dylibs** section
4. Tap **Add Dylib**
5. Select `libDeviceIDSpoofer.dylib`
6. Enable the dylib
7. Launch the app from LiveContainer

### Step 3: Verify injection

- The floating button should appear after 2 seconds
- Check Console.app for logs: `[DeviceIDSpoofer]`
- Tap the button to access device ID spoofing menu

## File Locations

### Build Output
```
.theos/obj/debug/libDeviceIDSpoofer.dylib          # Debug build
.theos/obj/debug/arm64/libDeviceIDSpoofer.dylib    # arm64 only
.theos/obj/debug/arm64e/libDeviceIDSpoofer.dylib   # arm64e only
```

### LiveContainer Locations (on device)
```
/var/mobile/Containers/Data/Application/[LIVECONTAINER-UUID]/Documents/Tweaks/
# Or wherever LiveContainer stores injected dylibs
```

## Preferences Storage

Since LiveContainer apps run in sandboxed containers, preferences are stored at:

```
# In the app's container (not system-wide)
/var/mobile/Containers/Data/Application/[APP-UUID]/Library/Preferences/com.marvenapps.deviceidspoofer.plist
```

**Note**: Each app will have its own separate preferences.

## Troubleshooting

### Dylib not loading

```bash
# Check dylib architecture
file libDeviceIDSpoofer.dylib
# Should show: Mach-O universal binary with 2 architectures: [arm64:Mach-O 64-bit dynamically linked shared library arm64] [arm64e]

# Check dependencies
otool -L libDeviceIDSpoofer.dylib

# Verify code signing (for non-jailbroken devices)
codesign -dv libDeviceIDSpoofer.dylib
```

### Floating button not appearing

1. Check Console logs for initialization messages
2. Verify UIKit is loaded in the target app
3. Ensure the app has UI (not a background service)
4. Try increasing the delay in `%ctor` from 2.0 to 5.0 seconds

### Preferences not persisting

- Each app injected has separate preferences
- Check the app's container path: `/var/mobile/Containers/Data/Application/[UUID]/Library/Preferences/`
- Ensure write permissions to the preferences directory

## Building for Distribution

### Strip debug symbols for smaller size

```bash
make -f Makefile.livecontainer FINALPACKAGE=1
strip -x .theos/obj/debug/libDeviceIDSpoofer.dylib

# Result will be ~200KB instead of ~2MB
```

### Code signing (if needed)

```bash
# Sign with your certificate
codesign -s "Your Certificate" libDeviceIDSpoofer.dylib

# Or ad-hoc signing
codesign -s - libDeviceIDSpoofer.dylib
```

## Architecture Support

- **arm64**: iPhone 5s to iPhone X, iPad Air and later
- **arm64e**: iPhone XS and later (A12+)

Both architectures are built by default for maximum compatibility.

## Quick Build Script

```bash
#!/bin/bash
# build_livecontainer.sh

set -e

echo "🔨 Building DeviceIDSpoofer for LiveContainer..."

# Clean
make -f Makefile.livecontainer clean

# Build
make -f Makefile.livecontainer FINALPACKAGE=1

# Strip
strip -x .theos/obj/debug/libDeviceIDSpoofer.dylib

# Show info
echo "✅ Build complete!"
file .theos/obj/debug/libDeviceIDSpoofer.dylib
ls -lh .theos/obj/debug/libDeviceIDSpoofer.dylib

echo ""
echo "📦 Dylib location: .theos/obj/debug/libDeviceIDSpoofer.dylib"
echo "📱 Copy to device and inject via LiveContainer"
```

## Differences from Tweak Build

| Aspect | Tweak (Cydia) | Dylib (LiveContainer) |
|--------|---------------|------------------------|
| Package | .deb | .dylib |
| Installation | dpkg/Cydia | LiveContainer |
| Injection | MobileSubstrate | LiveContainer |
| System-wide | Yes | No (per-app) |
| Preferences | System-wide | Per-app container |
| Requires | Jailbreak | TrollStore/LiveContainer |

## Compatibility

- ✅ iOS 15.0 - 18.0+
- ✅ LiveContainer 1.0+
- ✅ TrollStore (if LiveContainer installed via TrollStore)
- ✅ arm64 and arm64e devices

## Notes

- **No jailbreak required** when using LiveContainer
- **Per-app injection** means you can have different settings per app
- **Sandbox limitations** - can't access system-wide resources
- **MobileSubstrate hooks** still work via substrate substitute in LiveContainer

## Example: Inject into specific apps

```bash
# Build once
make -f Makefile.livecontainer FINALPACKAGE=1

# Inject into multiple apps via LiveContainer UI:
# - Instagram
# - Twitter/X
# - TikTok
# - Games
# - Any app that checks device IDs
```

Each app will have its own set of spoofed IDs that persist independently.
