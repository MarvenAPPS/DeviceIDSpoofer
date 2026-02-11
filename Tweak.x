#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "DeviceIDManager.h"
#import "FloatingButton.h"

static FloatingButton *floatingButton = nil;

// MARK: - Method Swizzling Helper

static void swizzleMethod(Class cls, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    
    if (!originalMethod || !swizzledMethod) {
        NSLog(@"[DeviceIDSpoofer] ⚠️ Failed to swizzle %@ - method not found", NSStringFromSelector(originalSelector));
        return;
    }
    
    BOOL didAddMethod = class_addMethod(cls,
                                       originalSelector,
                                       method_getImplementation(swizzledMethod),
                                       method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(cls,
                          swizzledSelector,
                          method_getImplementation(originalMethod),
                          method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    
    NSLog(@"[DeviceIDSpoofer] ✅ Swizzled %@", NSStringFromSelector(originalSelector));
}

// MARK: - UIDevice Category for IDFV Hook

@interface UIDevice (DeviceIDSpoofer)
- (NSUUID *)swizzled_identifierForVendor;
@end

@implementation UIDevice (DeviceIDSpoofer)

- (NSUUID *)swizzled_identifierForVendor {
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
    
    // Otherwise return original (calls swizzled method which is the original)
    NSUUID *original = [self swizzled_identifierForVendor];
    NSLog(@"[DeviceIDSpoofer] ➡️ IDFV ORIGINAL: %@", original.UUIDString);
    return original;
}

@end

// MARK: - Initialization

__attribute__((constructor))
static void initialize() {
    @autoreleasepool {
        NSLog(@"[DeviceIDSpoofer] 📦 Constructor called - LiveContainer mode");
        NSLog(@"[DeviceIDSpoofer] 🔧 Initializing profile system with manual swizzling...");
        
        // Initialize manager
        DeviceIDManager *manager = [DeviceIDManager sharedManager];
        NSLog(@"[DeviceIDSpoofer] Manager initialized - Current profile: %ld, Enabled: %@", 
              (long)manager.currentProfileIndex, 
              manager.isEnabled ? @"YES" : @"NO");
        
        // Swizzle UIDevice identifierForVendor
        swizzleMethod([UIDevice class], 
                     @selector(identifierForVendor), 
                     @selector(swizzled_identifierForVendor));
        
        // Show floating button after a delay
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            floatingButton = [[FloatingButton alloc] initWithDeviceIDManager:manager];
            [floatingButton show];
            NSLog(@"[DeviceIDSpoofer] ✅ Floating button initialized and shown");
        });
        
        NSLog(@"[DeviceIDSpoofer] ✅ Initialization complete");
    }
}
