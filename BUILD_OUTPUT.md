# Build Output Locations

## LiveContainer Dylib Build

### Build Command
```bash
make -f Makefile.livecontainer FINALPACKAGE=1
```

### Output Files

#### Individual Architectures
```
.theos/obj/arm64/libDeviceIDSpoofer.dylib       # arm64 only
.theos/obj/arm64e/libDeviceIDSpoofer.dylib      # arm64e only
```

#### Universal Binary (Not Created by Default)
To create a universal binary (fat binary with both architectures):

```bash
lipo -create \
  .theos/obj/arm64/libDeviceIDSpoofer.dylib \
  .theos/obj/arm64e/libDeviceIDSpoofer.dylib \
  -output output/libDeviceIDSpoofer.dylib
```

### Recommended Workflow

#### Option 1: Use VS Code Task (Easiest)
```
Cmd+Shift+P → "Tasks: Run Task" → "🚀 Build & Copy: LiveContainer (Output)"
```
This will:
1. Build both architectures
2. Create universal binary
3. Strip debug symbols
4. Copy to `output/` folder

#### Option 2: Manual Commands
```bash
# Build
make -f Makefile.livecontainer clean
make -f Makefile.livecontainer FINALPACKAGE=1

# Create output folder
mkdir -p output

# Copy individual architectures
cp .theos/obj/arm64/libDeviceIDSpoofer.dylib output/libDeviceIDSpoofer-arm64.dylib
cp .theos/obj/arm64e/libDeviceIDSpoofer.dylib output/libDeviceIDSpoofer-arm64e.dylib

# Create universal binary
lipo -create \
  .theos/obj/arm64/libDeviceIDSpoofer.dylib \
  .theos/obj/arm64e/libDeviceIDSpoofer.dylib \
  -output output/libDeviceIDSpoofer.dylib

# Strip symbols for smaller size
strip -x output/libDeviceIDSpoofer.dylib

# Verify
ls -lh output/
file output/libDeviceIDSpoofer.dylib
lipo -info output/libDeviceIDSpoofer.dylib
```

## Jailbreak Tweak Build

### Build Command
```bash
make clean package
```

### Output Files
```
packages/com.marvenapps.deviceidspoofer_1.0.0-X+debug_iphoneos-arm.deb
```

### Installed Location (on device)
```
/Library/MobileSubstrate/DynamicLibraries/DeviceIDSpoofer.dylib
/Library/MobileSubstrate/DynamicLibraries/DeviceIDSpoofer.plist
```

## Output Folder Structure

After running **"🎯 Build All: Dylib + Tweak"** task:

```
output/
├── libDeviceIDSpoofer.dylib              # Universal (arm64 + arm64e), stripped
├── libDeviceIDSpoofer-arm64.dylib        # arm64 only
├── libDeviceIDSpoofer-arm64e.dylib       # arm64e only
└── com.marvenapps.deviceidspoofer_*.deb  # Jailbreak package
```

## File Sizes

### Typical Sizes
```
arm64 dylib (with symbols):     ~1.5 MB
arm64e dylib (with symbols):    ~1.5 MB
Universal dylib (stripped):     ~400 KB
.deb package:                   ~50 KB
```

### Size Optimization
```bash
# Check current size
ls -lh .theos/obj/arm64/libDeviceIDSpoofer.dylib

# Strip debug symbols
strip -x .theos/obj/arm64/libDeviceIDSpoofer.dylib

# Check new size
ls -lh .theos/obj/arm64/libDeviceIDSpoofer.dylib

# Savings: ~70-80% size reduction
```

## Quick Reference

### Find Your Built Files
```bash
# Show all built dylibs
find .theos/obj -name "*.dylib" -type f

# Show all packages
ls -lh packages/

# Show output folder
ls -lh output/
```

### Which File to Use?

| Use Case | File to Use |
|----------|-------------|
| **LiveContainer** | `output/libDeviceIDSpoofer.dylib` (universal) |
| **LiveContainer (arm64 only)** | `.theos/obj/arm64/libDeviceIDSpoofer.dylib` |
| **LiveContainer (arm64e only)** | `.theos/obj/arm64e/libDeviceIDSpoofer.dylib` |
| **Jailbreak Install** | `packages/*.deb` |
| **Manual Injection** | Any of the above dylibs |

### Architecture Selection

| Device | Architecture | File |
|--------|--------------|------|
| iPhone 5s - X | arm64 | `libDeviceIDSpoofer-arm64.dylib` |
| iPhone XS+ (A12+) | arm64e | `libDeviceIDSpoofer-arm64e.dylib` |
| **Universal** | Both | `libDeviceIDSpoofer.dylib` |

**Recommendation**: Use the universal binary for maximum compatibility.

## Troubleshooting

### "No such file or directory"
```bash
# Make sure you built first
make -f Makefile.livecontainer FINALPACKAGE=1

# Check what was built
find .theos/obj -name "*.dylib" -type f
```

### "No output files"
The build creates files in `.theos/obj/`, not `output/`.

Use these VS Code tasks to copy to `output/`:
- **🚀 Build & Copy: LiveContainer (Output)**
- **🎯 Build All: Dylib + Tweak**

Or manually:
```bash
mkdir -p output
cp .theos/obj/arm64/libDeviceIDSpoofer.dylib output/
```

### "Dylib too large"
```bash
# Strip debug symbols
strip -x output/libDeviceIDSpoofer.dylib

# This reduces size by ~70-80%
```

## VS Code Tasks Summary

| Task | Output Location | Notes |
|------|-----------------|-------|
| **🔨 Build: LiveContainer Dylib** | `.theos/obj/arm64/` and `.theos/obj/arm64e/` | Build only, no copy |
| **🚀 Build & Copy: LiveContainer** | `output/` | Universal binary, stripped |
| **🎯 Build All** | `output/` | Both dylib and .deb |
| **📦 Build: Jailbreak Tweak** | `packages/` | .deb package |

## Quick Copy Commands

```bash
# Copy to Desktop
mkdir -p ~/Desktop/DeviceIDSpoofer
cp output/* ~/Desktop/DeviceIDSpoofer/

# Copy to device via SSH
scp output/libDeviceIDSpoofer.dylib root@DEVICE_IP:/var/root/

# Copy to specific location
cp output/libDeviceIDSpoofer.dylib /path/to/destination/
```
