#import "DeviceIDManager.h"
#import <UIKit/UIKit.h>

@implementation DeviceIDManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _isEnabled = NO;
        _advertisingTrackingEnabled = YES;
    }
    return self;
}

- (void)generateRandomIDs {
    // Generate random UUID-based identifiers
    self.customIDFV = [[NSUUID UUID] UUIDString];
    self.customIDFA = [[NSUUID UUID] UUIDString];
    self.customUDID = [[NSUUID UUID] UUIDString].uppercaseString;
    
    // Generate random serial number (12 characters)
    self.customSerialNumber = [self randomSerialNumber];
    
    // Generate random MAC addresses
    self.customWiFiMAC = [self randomMACAddress];
    self.customBluetoothMAC = [self randomMACAddress];
    
    // Generate random device info
    NSArray *models = @[@"iPhone12,1", @"iPhone13,2", @"iPhone14,2", @"iPhone14,3", @"iPhone15,2"];
    self.customProductType = models[arc4random_uniform((uint32_t)models.count)];
    
    NSArray *versions = @[@"15.0", @"15.5", @"16.0", @"16.5", @"17.0"];
    self.customSystemVersion = versions[arc4random_uniform((uint32_t)versions.count)];
    
    self.customDeviceName = [NSString stringWithFormat:@"iPhone-%@", [self randomString:4]];
    self.customModel = @"iPhone";
    self.customRegionInfo = @"US/A";
    
    [self saveSettings];
}

- (NSString *)randomSerialNumber {
    NSString *chars = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *serial = [NSMutableString string];
    for (int i = 0; i < 12; i++) {
        uint32_t index = arc4random_uniform((uint32_t)chars.length);
        [serial appendFormat:@"%C", [chars characterAtIndex:index]];
    }
    return serial;
}

- (NSString *)randomMACAddress {
    return [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
            arc4random_uniform(256),
            arc4random_uniform(256),
            arc4random_uniform(256),
            arc4random_uniform(256),
            arc4random_uniform(256),
            arc4random_uniform(256)];
}

- (NSString *)randomString:(NSInteger)length {
    NSString *chars = @"abcdefghijklmnopqrstuvwxyz0123456789";
    NSMutableString *result = [NSMutableString string];
    for (int i = 0; i < length; i++) {
        uint32_t index = arc4random_uniform((uint32_t)chars.length);
        [result appendFormat:@"%C", [chars characterAtIndex:index]];
    }
    return result;
}

- (void)resetToOriginal {
    self.customIDFV = nil;
    self.customIDFA = nil;
    self.customUDID = nil;
    self.customSerialNumber = nil;
    self.customWiFiMAC = nil;
    self.customBluetoothMAC = nil;
    self.customDeviceName = nil;
    self.customModel = nil;
    self.customProductType = nil;
    self.customSystemVersion = nil;
    self.customRegionInfo = nil;
    self.isEnabled = NO;
    [self saveSettings];
}

- (void)saveSettings {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    settings[@"isEnabled"] = @(self.isEnabled);
    settings[@"advertisingTrackingEnabled"] = @(self.advertisingTrackingEnabled);
    
    if (self.customIDFV) settings[@"customIDFV"] = self.customIDFV;
    if (self.customIDFA) settings[@"customIDFA"] = self.customIDFA;
    if (self.customUDID) settings[@"customUDID"] = self.customUDID;
    if (self.customSerialNumber) settings[@"customSerialNumber"] = self.customSerialNumber;
    if (self.customWiFiMAC) settings[@"customWiFiMAC"] = self.customWiFiMAC;
    if (self.customBluetoothMAC) settings[@"customBluetoothMAC"] = self.customBluetoothMAC;
    if (self.customDeviceName) settings[@"customDeviceName"] = self.customDeviceName;
    if (self.customModel) settings[@"customModel"] = self.customModel;
    if (self.customProductType) settings[@"customProductType"] = self.customProductType;
    if (self.customSystemVersion) settings[@"customSystemVersion"] = self.customSystemVersion;
    if (self.customRegionInfo) settings[@"customRegionInfo"] = self.customRegionInfo;
    
    NSString *path = @"/var/mobile/Library/Preferences/com.marvenapps.deviceidspoofer.plist";
    [settings writeToFile:path atomically:YES];
}

- (void)loadSettings {
    NSString *path = @"/var/mobile/Library/Preferences/com.marvenapps.deviceidspoofer.plist";
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if (settings) {
        self.isEnabled = [settings[@"isEnabled"] boolValue];
        self.advertisingTrackingEnabled = [settings[@"advertisingTrackingEnabled"] boolValue];
        self.customIDFV = settings[@"customIDFV"];
        self.customIDFA = settings[@"customIDFA"];
        self.customUDID = settings[@"customUDID"];
        self.customSerialNumber = settings[@"customSerialNumber"];
        self.customWiFiMAC = settings[@"customWiFiMAC"];
        self.customBluetoothMAC = settings[@"customBluetoothMAC"];
        self.customDeviceName = settings[@"customDeviceName"];
        self.customModel = settings[@"customModel"];
        self.customProductType = settings[@"customProductType"];
        self.customSystemVersion = settings[@"customSystemVersion"];
        self.customRegionInfo = settings[@"customRegionInfo"];
    }
}

- (NSDictionary *)getCurrentValues {
    UIDevice *device = [UIDevice currentDevice];
    
    return @{
        @"IDFV": self.customIDFV ?: ([device respondsToSelector:@selector(identifierForVendor)] ? [[device identifierForVendor] UUIDString] : @"N/A"),
        @"IDFA": self.customIDFA ?: @"N/A",
        @"UDID": self.customUDID ?: @"N/A",
        @"Serial Number": self.customSerialNumber ?: @"N/A",
        @"WiFi MAC": self.customWiFiMAC ?: @"N/A",
        @"Bluetooth MAC": self.customBluetoothMAC ?: @"N/A",
        @"Device Name": self.customDeviceName ?: device.name,
        @"Model": self.customModel ?: device.model,
        @"Product Type": self.customProductType ?: @"N/A",
        @"System Version": self.customSystemVersion ?: device.systemVersion,
        @"Region Info": self.customRegionInfo ?: @"N/A"
    };
}

- (void)setCustomValue:(NSString *)value forKey:(NSString *)key {
    if ([key isEqualToString:@"IDFV"]) self.customIDFV = value;
    else if ([key isEqualToString:@"IDFA"]) self.customIDFA = value;
    else if ([key isEqualToString:@"UDID"]) self.customUDID = value;
    else if ([key isEqualToString:@"Serial Number"]) self.customSerialNumber = value;
    else if ([key isEqualToString:@"WiFi MAC"]) self.customWiFiMAC = value;
    else if ([key isEqualToString:@"Bluetooth MAC"]) self.customBluetoothMAC = value;
    else if ([key isEqualToString:@"Device Name"]) self.customDeviceName = value;
    else if ([key isEqualToString:@"Model"]) self.customModel = value;
    else if ([key isEqualToString:@"Product Type"]) self.customProductType = value;
    else if ([key isEqualToString:@"System Version"]) self.customSystemVersion = value;
    else if ([key isEqualToString:@"Region Info"]) self.customRegionInfo = value;
    
    [self saveSettings];
}

@end
