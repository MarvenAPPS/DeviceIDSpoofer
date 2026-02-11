# Device ID Spoofer

🎯 **Simple, fast IDFV spoofing with 10 predefined profiles**

## Features

- 🎮 **10 Predefined Profiles** - Gaming, Social, Finance, Shopping, Media, Work, Testing, Privacy, Development, Default
- ⚡ **One-Tap Switching** - Tap floating button to cycle through profiles
- 🔄 **Auto-Disable** - After 10 taps (all profiles), returns to disabled state
- 💾 **Persistent State** - Remembers current profile across app restarts
- 📊 **Visual Feedback** - Shows profile name and IDFV in toast notification
- 🎨 **Status Indicator** - Button shows "OFF" or "P1"-"P10"

## How It Works

### Profile Cycling

1. **Initial State**: Disabled (Gray button, "OFF")
2. **Tap 1**: Profile 1 - Gaming (Blue button, "P1")
3. **Tap 2**: Profile 2 - Social (Blue button, "P2")
4. **...**
5. **Tap 10**: Profile 10 - Default (Blue button, "P10")
6. **Tap 11**: Back to Disabled (Gray button, "OFF")

### Visual States

- 🔴 **Disabled**: Gray button with "OFF" label
- 🔵 **Active Profile**: Blue button with "P1" through "P10" label
- 🎨 **Toast Notification**: Shows profile name + first 8 chars of IDFV

## Profiles

| # | Profile Name | IDFV |
|---|-------------|------|
| 1 | Gaming | `12345678-AAAA-BBBB-CCCC-111111111111` |
| 2 | Social | `87654321-BBBB-CCCC-DDDD-222222222222` |
| 3 | Finance | `ABCDEFAB-CCCC-DDDD-EEEE-333333333333` |
| 4 | Shopping | `FEDCBAFE-DDDD-EEEE-FFFF-444444444444` |
| 5 | Media | `11111111-EEEE-FFFF-0000-555555555555` |
| 6 | Work | `22222222-FFFF-0000-1111-666666666666` |
| 7 | Testing | `33333333-0000-1111-2222-777777777777` |
| 8 | Privacy | `44444444-1111-2222-3333-888888888888` |
| 9 | Development | `55555555-2222-3333-4444-999999999999` |
| 10 | Default | `66666666-3333-4444-5555-AAAAAAAAAAAA` |

## Installation

### Build & Install

```bash
cd DeviceIDSpoofer
make clean package install
```

### Requirements

- iOS 14.0+
- Theos installed
- Jailbroken device or LiveContainer

## Usage

1. **Launch app** - Floating button appears automatically
2. **Tap button** - Cycles to next profile
3. **Check toast** - See current profile name and IDFV
4. **Drag button** - Move anywhere on screen
5. **Keep tapping** - After 10 taps, returns to disabled

## Technical Details

### Hook Mechanism

- **Target Method**: `[UIDevice identifierForVendor]`
- **Hook Type**: Logos `%hook` with `%orig` fallback
- **Return Value**: `NSUUID` object with spoofed or original IDFV

### State Management

- **Storage**: `NSUserDefaults`
- **Keys**: `CurrentProfileIndex` (-1 to 9), `DeviceIDSpoofingEnabled`
- **Persistence**: Survives app restarts and resprings

### Components

- **Tweak.x**: IDFV hook and initialization
- **DeviceIDManager**: Profile data and state management
- **FloatingButton**: UI and user interaction
- **UIManager**: Advanced menu (optional, for future use)

## Logs

Monitor with:

```bash
tail -f /var/log/syslog | grep DeviceIDSpoofer
```

You'll see:

```
[DeviceIDSpoofer] 🟢 Switched to profile 1: Profile 1: Gaming -> 12345678
[DeviceIDSpoofer] 🔄 IDFV HOOKED: 12345678-AAAA-BBBB-CCCC-111111111111 (Profile 1: Gaming)
[DeviceIDSpoofer] 🟢 Switched to profile 2: Profile 2: Social -> 87654321
...
[DeviceIDSpoofer] 🔴 Profile cycling complete - DISABLED
[DeviceIDSpoofer] ➡️ IDFV ORIGINAL: [original-uuid]
```

## Customization

To add your own profiles, edit `DeviceIDManager.m`:

```objc
profiles = @{
    @"Profile 1: Your Name": @"YOUR-UUID-HERE",
    @"Profile 2: Another Name": @"ANOTHER-UUID-HERE",
    // ...
};
```

Generate UUIDs with:

```bash
uuidgen
```

## Roadmap

- [ ] IDFA spoofing support
- [ ] Custom profile editor via UI
- [ ] Import/export profile configurations
- [ ] Per-app profile selection
- [ ] UDID, Serial Number, MAC address spoofing

## License

MIT License - Use freely!

## Author

Marven - [@MarvenAPPS](https://github.com/MarvenAPPS)
