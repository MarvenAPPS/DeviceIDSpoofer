#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import "DeviceIDManager.h"
#import "FloatingWindow.h"
#import "UIManager.h"

static FloatingWindow *floatingWindow = nil;
static DeviceIDManager *deviceIDManager = nil;

// MARK: - UIDevice Hooks

%hook UIDevice

- (NSString *)identifierForVendor {
    if (deviceIDManager.isEnabled && deviceIDManager.customIDFV) {
        return deviceIDManager.customIDFV;
    }
    return %orig;
}

- (NSString *)name {
    if (deviceIDManager.isEnabled && deviceIDManager.customDeviceName) {
        return deviceIDManager.customDeviceName;
    }
    return %orig;
}

- (NSString *)model {
    if (deviceIDManager.isEnabled && deviceIDManager.customModel) {
        return deviceIDManager.customModel;
    }
    return %orig;
}

- (NSString *)systemVersion {
    if (deviceIDManager.isEnabled && deviceIDManager.customSystemVersion) {
        return deviceIDManager.customSystemVersion;
    }
    return %orig;
}

%end

// MARK: - ASIdentifierManager Hooks (Advertising ID)

%hook ASIdentifierManager

- (NSUUID *)advertisingIdentifier {
    if (deviceIDManager.isEnabled && deviceIDManager.customIDFA) {
        return [[NSUUID alloc] initWithUUIDString:deviceIDManager.customIDFA];
    }
    return %orig;
}

- (BOOL)isAdvertisingTrackingEnabled {
    if (deviceIDManager.isEnabled) {
        return deviceIDManager.advertisingTrackingEnabled;
    }
    return %orig;
}

%end

// MARK: - MobileGestalt Hooks

static CFTypeRef (*original_MGCopyAnswer)(CFStringRef question);

CFTypeRef replacement_MGCopyAnswer(CFStringRef question) {
    if (!deviceIDManager.isEnabled) {
        return original_MGCopyAnswer(question);
    }
    
    NSString *key = (__bridge NSString *)question;
    
    // Serial Number
    if ([key isEqualToString:@"SerialNumber"] && deviceIDManager.customSerialNumber) {
        return (__bridge_retained CFTypeRef)deviceIDManager.customSerialNumber;
    }
    
    // UDID
    if ([key isEqualToString:@"UniqueDeviceID"] && deviceIDManager.customUDID) {
        return (__bridge_retained CFTypeRef)deviceIDManager.customUDID;
    }
    
    // WiFi Address (MAC)
    if ([key isEqualToString:@"WifiAddress"] && deviceIDManager.customWiFiMAC) {
        return (__bridge_retained CFTypeRef)deviceIDManager.customWiFiMAC;
    }
    
    // Bluetooth Address (MAC)
    if ([key isEqualToString:@"BluetoothAddress"] && deviceIDManager.customBluetoothMAC) {
        return (__bridge_retained CFTypeRef)deviceIDManager.customBluetoothMAC;
    }
    
    // Device Model
    if ([key isEqualToString:@"ProductType"] && deviceIDManager.customProductType) {
        return (__bridge_retained CFTypeRef)deviceIDManager.customProductType;
    }
    
    // Region Info
    if ([key isEqualToString:@"RegionInfo"] && deviceIDManager.customRegionInfo) {
        return (__bridge_retained CFTypeRef)deviceIDManager.customRegionInfo;
    }
    
    return original_MGCopyAnswer(question);
}

// MARK: - Constructor

%ctor {
    @autoreleasepool {
        NSLog(@"[DeviceIDSpoofer] Initializing...");
        
        // Initialize managers
        deviceIDManager = [[DeviceIDManager alloc] init];
        [deviceIDManager loadSettings];
        
        // Hook MobileGestalt
        void *handle = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_NOW);
        if (handle) {
            original_MGCopyAnswer = (CFTypeRef (*)(CFStringRef))dlsym(handle, "MGCopyAnswer");
            if (original_MGCopyAnswer) {
                MSHookFunction((void *)original_MGCopyAnswer, (void *)replacement_MGCopyAnswer, (void **)&original_MGCopyAnswer);
                NSLog(@"[DeviceIDSpoofer] MobileGestalt hooked successfully");
            }
        }
        
        // Initialize floating window after a delay
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            floatingWindow = [[FloatingWindow alloc] initWithDeviceIDManager:deviceIDManager];
            [floatingWindow show];
            NSLog(@"[DeviceIDSpoofer] Floating window initialized");
        });
    }
}
