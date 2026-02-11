# DeviceIDSpoofer

<div align="center">

**Injectable iOS Dylib for Device ID Spoofing**

[![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://www.apple.com/ios/)
[![Architecture](https://img.shields.io/badge/arch-arm64%20%7C%20arm64e-green.svg)](https://developer.apple.com/documentation/apple-silicon)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)

*Hook and spoof all iOS device unique identifiers with an intuitive floating UI*

</div>

---

## 🔥 Features

- **🎯 Floating Button UI**: Draggable, non-intrusive interface accessible from any app
- **🔑 Complete ID Coverage**: Hooks all major device identifiers
  - IDFV (Identifier For Vendor)
  - IDFA (Advertising Identifier)
  - UDID (Unique Device ID)
  - Serial Number
  - WiFi MAC Address
  - Bluetooth MAC Address
  - Device Name, Model, Product Type
  - System Version, Region Info
- **⚡ Real-time Toggle**: Enable/disable spoofing on-the-fly
- **🎲 Random Generation**: One-tap random ID generation
- **✏️ Custom Values**: Manually set any identifier to specific values
- **💾 Persistent Storage**: Settings saved across app launches
- **🎯 MobileGestalt Hooks**: Low-level system hooks for maximum coverage

---

## 📸 Screenshots

### Floating Button
A draggable floating button that snaps to screen edges for easy access.

### Menu Interface
Clean, intuitive interface showing all device identifiers with current values.

---

## 🛠️ Installation

### Prerequisites

1. **Jailbroken iOS Device** (iOS 15.0 or higher)
2. **Theos** installed on your development machine
3. **SSH access** to your device
4. **Basic knowledge** of iOS tweak development

### Option 1: Build from Source

```bash
# Clone the repository
git clone https://github.com/MarvenAPPS/DeviceIDSpoofer.git
cd DeviceIDSpoofer

# Set your device IP (or use make do if configured)
export THEOS_DEVICE_IP=YOUR_DEVICE_IP

# Build and install
make clean package install

# Respring your device
killall -9 SpringBoard
```

### Option 2: Install Pre-built Package

```bash
# Download the .deb file from Releases
# Transfer to your device and install
ssh root@YOUR_DEVICE_IP
dpkg -i com.marvenapps.deviceidspoofer_1.0.0_iphoneos-arm.deb
killall -9 SpringBoard
```

---

## 🚀 Usage

### Basic Operation

1. **Launch any app** - The floating button appears after 2 seconds
2. **Tap the button** - Opens the Device ID Spoofer menu
3. **Enable spoofing** - Toggle the master switch
4. **Generate IDs** - Tap "Generate" for random values
5. **Custom values** - Tap any ID to set a custom value
6. **Reset** - Tap "Reset" to restore original device IDs

### Advanced Features

#### Moving the Floating Button
- **Long press and drag** to reposition
- **Automatically snaps** to nearest screen edge
- **Persists position** across app launches

#### Editing Individual IDs
1. Tap any identifier in the list
2. Enter your custom value
3. Tap "Save"
4. Changes take effect immediately

#### Bulk Operations
- **Generate**: Creates completely random IDs for all fields
- **Reset**: Clears all custom values and disables spoofing

---

## 📚 Technical Details

### Hooked APIs

#### UIDevice (UIKit)
```objc
- identifierForVendor
- name
- model
- systemVersion
```

#### ASIdentifierManager (AdSupport)
```objc
- advertisingIdentifier
- isAdvertisingTrackingEnabled
```

#### MobileGestalt (Private Framework)
```c
MGCopyAnswer() with keys:
- SerialNumber
- UniqueDeviceID
- WifiAddress
- BluetoothAddress
- ProductType
- RegionInfo
```

### Architecture

```
┌───────────────────────┐
│   FloatingWindow.m    │
│  (UI Entry Point)     │
└─────────┬────────────┘
         │
         │ User Interaction
         │
┌────────┴────────┐
│   UIManager.m    │
│ (Menu & Controls) │
└────────┬────────┘
         │
         │ State Management
         │
┌────────┴───────────────┐
│  DeviceIDManager.m   │
│  (ID Generation &    │
│   Persistence)       │
└────────┬───────────────┘
         │
         │ Provides Spoofed Values
         │
┌────────┴──────────────┐
│      Tweak.x        │
│ (Method Swizzling & │
│  Function Hooking)  │
└────────┬──────────────┘
         │
         │ Intercepts
         │
┌────────┴──────────────┐
│   System APIs     │
│  UIDevice, ASIM,  │
│  MobileGestalt    │
└───────────────────────┘
```

### File Structure

```
DeviceIDSpoofer/
├── Tweak.x                  # Main hooks and constructor
├── DeviceIDManager.h/m      # ID management logic
├── FloatingWindow.h/m       # Floating button UI
├── UIManager.h/m            # Menu interface
├── Makefile                 # Build configuration
├── control                  # Package metadata
└── README.md                # This file
```

---

## ⚙️ Configuration

### Preferences File

Settings are stored in:
```
/var/mobile/Library/Preferences/com.marvenapps.deviceidspoofer.plist
```

### Preferences Structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>isEnabled</key>
    <true/>
    <key>customIDFV</key>
    <string>XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX</string>
    <key>customIDFA</key>
    <string>XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX</string>
    <!-- Additional keys... -->
</dict>
</plist>
```

---

## 🛡️ Privacy & Security

### ⚠️ Important Notes

- **Educational Purpose**: This tool is for research and testing only
- **Responsible Use**: Do not use for malicious purposes or to violate ToS
- **Detection Risk**: Some apps may detect modified device IDs
- **App Store**: Works only on jailbroken devices

### Best Practices

1. **Test in sandbox**: Use with test accounts first
2. **Consistent IDs**: Keep generated IDs consistent per app
3. **Realistic values**: Use plausible device configurations
4. **Disable when not needed**: Toggle off to reduce detection risk

---

## 🐛 Troubleshooting

### Floating Button Not Appearing

```bash
# Check if tweak is loaded
ps aux | grep DeviceIDSpoofer

# Check logs
log stream --predicate 'process == "SpringBoard"' | grep DeviceID

# Reinstall
make clean package install
killall -9 SpringBoard
```

### IDs Not Being Spoofed

1. Ensure master switch is **enabled**
2. Check that custom values are **set**
3. Verify app is **not in blacklist**
4. Try **restarting the app**

### Build Errors

```bash
# Update Theos
$THEOS/bin/update-theos

# Clean build
make clean

# Check Theos installation
echo $THEOS
```

---

## 📝 Logging

Enable detailed logging:

```bash
# View live logs
log stream --predicate 'subsystem == "com.marvenapps.deviceidspoofer"' --level debug

# Or use Console.app on macOS
# Filter: process:SpringBoard AND message:DeviceID
```

---

## 🔧 Development

### Building for Development

```bash
# Development build with symbols
make clean
make DEBUG=1 package install

# Watch logs
make install && log stream --predicate 'process == "SpringBoard"' | grep DeviceID
```

### Adding New Hooks

1. Edit `Tweak.x`
2. Add hook using Logos syntax
3. Update `DeviceIDManager` with new properties
4. Update UI in `UIManager.m`
5. Rebuild and test

### Testing

```bash
# Test specific app
open -b com.example.app

# Monitor hooks
log stream --predicate 'process == "YourApp"' | grep DeviceID
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Code Style

- Follow **Apple's Objective-C conventions**
- Use **ARC** (Automatic Reference Counting)
- Add **comments** for complex logic
- Test on **multiple iOS versions**

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Disclaimer

**FOR EDUCATIONAL AND RESEARCH PURPOSES ONLY**

This tool is provided as-is for educational purposes. The authors are not responsible for any misuse or damage caused by this software. Use at your own risk and comply with all applicable laws and terms of service.

---

## 🚀 Roadmap

- [ ] Add app-specific ID profiles
- [ ] Import/Export configurations
- [ ] Scheduled ID rotation
- [ ] Blacklist/Whitelist apps
- [ ] Dark mode support
- [ ] Landscape mode optimization
- [ ] Preferences panel in Settings.app
- [ ] Remote configuration via web panel

---

## 💬 Support

For issues, questions, or suggestions:

- **GitHub Issues**: [Report a bug](https://github.com/MarvenAPPS/DeviceIDSpoofer/issues)
- **Discussions**: [Ask a question](https://github.com/MarvenAPPS/DeviceIDSpoofer/discussions)

---

## 🌟 Acknowledgments

- **Theos** - iOS tweak development framework
- **Cydia Substrate** - Runtime patching engine
- **iOS Reverse Engineering Community** - Knowledge and inspiration

---

## 📊 Version History

### v1.0.0 (Current)
- Initial release
- Floating button UI
- All major device ID hooks
- Random generation
- Custom value support
- Persistent storage

---

<div align="center">

**Made with ❤️ by [MarvenAPPS](https://github.com/MarvenAPPS)**

If you find this useful, consider giving it a ⭐️

</div>
