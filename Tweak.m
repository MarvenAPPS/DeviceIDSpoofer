#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "DeviceIDManager.h"
#import "FloatingButton.h"

static FloatingButton *floatingButton = nil;
static BOOL hookingInitialized = NO;

// MARK: - Toast Helper

static void showDebugToast(NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Get key window
        UIWindow *keyWindow = nil;
        
        if (@available(iOS 15.0, *)) {
            NSSet<UIScene *> *connectedScenes = [UIApplication sharedApplication].connectedScenes;
            for (UIScene *scene in connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    for (UIWindow *window in windowScene.windows) {
                        if (window.isKeyWindow) {
                            keyWindow = window;
                            break;
                        }
                    }
                    if (!keyWindow && windowScene.windows.count > 0) {
                        keyWindow = windowScene.windows.firstObject;
                    }
                    if (keyWindow) break;
                }
            }
        } else {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                if (window.isKeyWindow) {
                    keyWindow = window;
                    break;
                }
            }
            if (!keyWindow) {
                keyWindow = [UIApplication sharedApplication].windows.firstObject;
            }
            #pragma clang diagnostic pop
        }
        
        if (!keyWindow) {
            NSLog(@"[DeviceIDSpoofer] No window for toast");
            return;
        }
        
        // Create toast - LARGER and MORE READABLE
        UILabel *toast = [[UILabel alloc] initWithFrame:CGRectMake(20, 150, keyWindow.bounds.size.width - 40, 140)];
        toast.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.95];
        toast.textColor = [UIColor whiteColor];
        toast.textAlignment = NSTextAlignmentCenter;
        toast.numberOfLines = 0;
        toast.font = [UIFont boldSystemFontOfSize:14]; // Larger font
        toast.layer.cornerRadius = 15;
        toast.clipsToBounds = YES;
        toast.text = message;
        toast.alpha = 0;
        
        // Add border for visibility
        toast.layer.borderWidth = 2;
        toast.layer.borderColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0].CGColor;
        
        [keyWindow addSubview:toast];
        
        // Fade in
        [UIView animateWithDuration:0.3 animations:^{
            toast.alpha = 1.0;
        } completion:^(BOOL finished) {
            // Stay for 5 seconds (was 2 seconds)
            [UIView animateWithDuration:0.3 delay:5.0 options:0 animations:^{
                toast.alpha = 0;
            } completion:^(BOOL finished) {
                [toast removeFromSuperview];
            }];
        }];
    });
}

// MARK: - Method Swizzling Helper

static void swizzleMethod(Class cls, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    
    if (!originalMethod || !swizzledMethod) {
        NSLog(@"[DeviceIDSpoofer] ⚠️ Failed to swizzle %@ - method not found", NSStringFromSelector(originalSelector));
        showDebugToast([NSString stringWithFormat:@"❌ Hook FAILED\n%@ not found", NSStringFromSelector(originalSelector)]);
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
    showDebugToast([NSString stringWithFormat:@"✅ HOOK INSTALLED\n\n%@\n\nTap floating button to\nswitch profiles", NSStringFromSelector(originalSelector)]);
}

// MARK: - UIDevice Category for IDFV Hook

@interface UIDevice (DeviceIDSpoofer)
- (NSUUID *)swizzled_identifierForVendor;
@end

@implementation UIDevice (DeviceIDSpoofer)

- (NSUUID *)swizzled_identifierForVendor {
    // Get original first
    NSUUID *original = [self swizzled_identifierForVendor]; // This calls the original method
    
    DeviceIDManager *manager = [DeviceIDManager sharedManager];
    
    // If enabled and profile is active, return spoofed IDFV
    if (manager.isEnabled && manager.currentProfileIndex >= 0) {
        NSString *spoofedIDFV = [manager getCurrentProfileIDFV];
        NSUUID *spoofed = [[NSUUID alloc] initWithUUIDString:spoofedIDFV];
        
        NSLog(@"[DeviceIDSpoofer] 🔄 IDFV HOOKED!");
        NSLog(@"[DeviceIDSpoofer]    Original: %@", original.UUIDString);
        NSLog(@"[DeviceIDSpoofer]    Spoofed:  %@ (Profile %ld: %@)", 
              spoofedIDFV, 
              (long)manager.currentProfileIndex + 1,
              [manager getCurrentProfileName]);
        
        // Show diagnostic toast with FULL UUIDs
        NSString *toastMsg = [NSString stringWithFormat:@"🔄 IDFV HOOKED!\n\n📱 Original:\n%@\n\n🎭 Spoofed:\n%@\n\nProfile %ld: %@",
                             original.UUIDString,
                             spoofedIDFV,
                             (long)manager.currentProfileIndex + 1,
                             [manager getCurrentProfileName]];
        showDebugToast(toastMsg);
        
        return spoofed;
    }
    
    // Return original
    NSLog(@"[DeviceIDSpoofer] ➡️ IDFV ORIGINAL (hooking disabled): %@", original.UUIDString);
    
    // Show diagnostic toast
    NSString *toastMsg = [NSString stringWithFormat:@"➡️ IDFV NOT HOOKED\n\n📱 Original IDFV:\n%@\n\n(Spoofing is disabled)\n\nTap floating button to enable",
                         original.UUIDString];
    showDebugToast(toastMsg);
    
    return original;
}

@end

// MARK: - Test Function

static void testHook() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[DeviceIDSpoofer] 🧪 Testing hook by calling [UIDevice identifierForVendor]...");
        NSUUID *testIDFV = [[UIDevice currentDevice] identifierForVendor];
        NSLog(@"[DeviceIDSpoofer] 🧪 Test result: %@", testIDFV.UUIDString);
    });
}

// MARK: - Initialization

__attribute__((constructor))
static void initialize() {
    @autoreleasepool {
        NSLog(@"[DeviceIDSpoofer] 📦 Constructor called - LiveContainer mode");
        NSLog(@"[DeviceIDSpoofer] 🔧 Process: %@", [[NSProcessInfo processInfo] processName]);
        NSLog(@"[DeviceIDSpoofer] 🔧 Bundle ID: %@", [[NSBundle mainBundle] bundleIdentifier]);
        
        showDebugToast(@"📦 DeviceIDSpoofer\n\nInitializing...\n\nPlease wait");
        
        // Initialize manager
        DeviceIDManager *manager = [DeviceIDManager sharedManager];
        NSLog(@"[DeviceIDSpoofer] Manager initialized - Current profile: %ld, Enabled: %@", 
              (long)manager.currentProfileIndex, 
              manager.isEnabled ? @"YES" : @"NO");
        
        // Swizzle UIDevice identifierForVendor
        NSLog(@"[DeviceIDSpoofer] 🔨 Installing hook...");
        swizzleMethod([UIDevice class], 
                     @selector(identifierForVendor), 
                     @selector(swizzled_identifierForVendor));
        
        hookingInitialized = YES;
        
        // Test the hook after 4 seconds (was 3)
        testHook();
        
        // Show floating button after a delay
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            floatingButton = [[FloatingButton alloc] initWithDeviceIDManager:manager];
            [floatingButton show];
            NSLog(@"[DeviceIDSpoofer] ✅ Floating button initialized and shown");
        });
        
        NSLog(@"[DeviceIDSpoofer] ✅ Initialization complete");
    }
}
