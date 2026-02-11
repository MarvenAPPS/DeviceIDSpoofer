#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import "DeviceIDManager.h"
#import "FloatingWindow.h"
#import "UIManager.h"

static FloatingWindow *floatingWindow = nil;
static DeviceIDManager *deviceIDManager = nil;

// MARK: - Method Swizzling Helper

static void swizzleMethod(Class cls, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    
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
}

// MARK: - UIDevice Category

@interface UIDevice (DeviceIDSpoofer)
- (NSString *)swizzled_identifierForVendor;
- (NSString *)swizzled_name;
- (NSString *)swizzled_model;
- (NSString *)swizzled_systemVersion;
@end

@implementation UIDevice (DeviceIDSpoofer)

- (NSString *)swizzled_identifierForVendor {
    if (deviceIDManager.isEnabled && deviceIDManager.customIDFV) {
        return deviceIDManager.customIDFV;
    }
    return [self swizzled_identifierForVendor]; // Calls original
}

- (NSString *)swizzled_name {
    if (deviceIDManager.isEnabled && deviceIDManager.customDeviceName) {
        return deviceIDManager.customDeviceName;
    }
    return [self swizzled_name]; // Calls original
}

- (NSString *)swizzled_model {
    if (deviceIDManager.isEnabled && deviceIDManager.customModel) {
        return deviceIDManager.customModel;
    }
    return [self swizzled_model]; // Calls original
}

- (NSString *)swizzled_systemVersion {
    if (deviceIDManager.isEnabled && deviceIDManager.customSystemVersion) {
        return deviceIDManager.customSystemVersion;
    }
    return [self swizzled_systemVersion]; // Calls original
}

@end

// MARK: - ASIdentifierManager Category

@interface ASIdentifierManager (DeviceIDSpoofer)
- (NSUUID *)swizzled_advertisingIdentifier;
- (BOOL)swizzled_isAdvertisingTrackingEnabled;
@end

@implementation ASIdentifierManager (DeviceIDSpoofer)

- (NSUUID *)swizzled_advertisingIdentifier {
    if (deviceIDManager.isEnabled && deviceIDManager.customIDFA) {
        return [[NSUUID alloc] initWithUUIDString:deviceIDManager.customIDFA];
    }
    return [self swizzled_advertisingIdentifier]; // Calls original
}

- (BOOL)swizzled_isAdvertisingTrackingEnabled {
    if (deviceIDManager.isEnabled) {
        return deviceIDManager.advertisingTrackingEnabled;
    }
    return [self swizzled_isAdvertisingTrackingEnabled]; // Calls original
}

@end

// MARK: - MobileGestalt Hooks (Using fishhook-style approach)

static CFTypeRef (*original_MGCopyAnswer)(CFStringRef question) = NULL;

CFTypeRef replacement_MGCopyAnswer(CFStringRef question) {
    if (!deviceIDManager.isEnabled || !original_MGCopyAnswer) {
        return original_MGCopyAnswer ? original_MGCopyAnswer(question) : NULL;
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

// Simple function pointer replacement (works in LiveContainer)
static void hookMobileGestalt() {
    void *handle = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_NOW);
    if (!handle) {
        NSLog(@"[DeviceIDSpoofer] Failed to load MobileGestalt");
        return;
    }
    
    void *mgCopyAnswer = dlsym(handle, "MGCopyAnswer");
    if (!mgCopyAnswer) {
        NSLog(@"[DeviceIDSpoofer] Failed to find MGCopyAnswer");
        dlclose(handle);
        return;
    }
    
    original_MGCopyAnswer = (CFTypeRef (*)(CFStringRef))mgCopyAnswer;
    
    // Note: For full MobileGestalt hooking in LiveContainer, you'd need fishhook
    // For now, we'll rely on UIDevice hooks which cover most use cases
    NSLog(@"[DeviceIDSpoofer] MobileGestalt found (limited hooking in LiveContainer)");
}

// MARK: - Initialization

__attribute__((constructor))
static void initialize() {
    @autoreleasepool {
        NSLog(@"[DeviceIDSpoofer] Initializing LiveContainer-compatible version...");
        
        // Initialize managers
        deviceIDManager = [[DeviceIDManager alloc] init];
        [deviceIDManager loadSettings];
        
        // Swizzle UIDevice methods
        swizzleMethod([UIDevice class], @selector(identifierForVendor), @selector(swizzled_identifierForVendor));
        swizzleMethod([UIDevice class], @selector(name), @selector(swizzled_name));
        swizzleMethod([UIDevice class], @selector(model), @selector(swizzled_model));
        swizzleMethod([UIDevice class], @selector(systemVersion), @selector(swizzled_systemVersion));
        
        // Swizzle ASIdentifierManager methods
        Class asIdentifierClass = NSClassFromString(@"ASIdentifierManager");
        if (asIdentifierClass) {
            swizzleMethod(asIdentifierClass, @selector(advertisingIdentifier), @selector(swizzled_advertisingIdentifier));
            swizzleMethod(asIdentifierClass, @selector(isAdvertisingTrackingEnabled), @selector(swizzled_isAdvertisingTrackingEnabled));
            NSLog(@"[DeviceIDSpoofer] ASIdentifierManager hooks installed");
        }
        
        // Attempt MobileGestalt hook (limited in LiveContainer)
        hookMobileGestalt();
        
        // Initialize floating window after a delay
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            floatingWindow = [[FloatingWindow alloc] initWithDeviceIDManager:deviceIDManager];
            [floatingWindow show];
            NSLog(@"[DeviceIDSpoofer] Floating window initialized");
        });
        
        NSLog(@"[DeviceIDSpoofer] Initialization complete");
    }
}
