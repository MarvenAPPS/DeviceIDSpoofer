#import <UIKit/UIKit.h>
#import "DeviceIDManager.h"
#import "FloatingButton.h"

static FloatingButton *floatingButton = nil;

// Hook UIDevice identifierForVendor (IDFV) using Logos
%hook UIDevice

- (NSUUID *)identifierForVendor {
    DeviceIDManager *manager = [DeviceIDManager sharedManager];
    
    // If enabled and profile is active, return spoofed IDFV
    if (manager.isEnabled && manager.currentProfileIndex >= 0) {
        NSString *spoofedIDFV = [manager getCurrentProfileIDFV];
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:spoofedIDFV];
        
        NSLog(@"[DeviceIDSpoofer] 🔄 IDFV HOOKED: %@ (Profile %ld: %@)", 
              spoofedIDFV, 
              (long)manager.currentProfileIndex + 1,
              [manager getCurrentProfileName]);
        
        return uuid;
    }
    
    // Otherwise return original
    NSUUID *original = %orig;
    NSLog(@"[DeviceIDSpoofer] ➡️ IDFV ORIGINAL: %@", original.UUIDString);
    return original;
}

%end

// Hook ASIdentifierManager identifierForAdvertising (IDFA) - Optional for future
%hook ASIdentifierManager

- (NSUUID *)advertisingIdentifier {
    DeviceIDManager *manager = [DeviceIDManager sharedManager];
    
    if (manager.isEnabled && manager.currentProfileIndex >= 0) {
        NSLog(@"[DeviceIDSpoofer] 📺 IDFA requested (not spoofed yet)");
    }
    
    return %orig;
}

%end

// Initialize floating button on app launch
%ctor {
    NSLog(@"[DeviceIDSpoofer] 📦 Constructor called - Initializing profile system");
    
    DeviceIDManager *manager = [DeviceIDManager sharedManager];
    NSLog(@"[DeviceIDSpoofer] Manager initialized - Current profile: %ld, Enabled: %@", 
          (long)manager.currentProfileIndex, 
          manager.isEnabled ? @"YES" : @"NO");
    
    // Show floating button after a delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        floatingButton = [[FloatingButton alloc] initWithDeviceIDManager:manager];
        [floatingButton show];
        NSLog(@"[DeviceIDSpoofer] ✅ Floating button initialized and shown");
    });
}
