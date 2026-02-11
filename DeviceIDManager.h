#import <Foundation/Foundation.h>

@interface DeviceIDManager : NSObject

// Enable/Disable spoofing
@property (nonatomic, assign) BOOL isEnabled;

// Device Identifiers
@property (nonatomic, strong) NSString *customIDFV;              // Identifier For Vendor
@property (nonatomic, strong) NSString *customIDFA;              // Identifier For Advertisers
@property (nonatomic, strong) NSString *customUDID;              // Unique Device ID
@property (nonatomic, strong) NSString *customSerialNumber;      // Serial Number
@property (nonatomic, strong) NSString *customWiFiMAC;           // WiFi MAC Address
@property (nonatomic, strong) NSString *customBluetoothMAC;      // Bluetooth MAC Address

// Device Info
@property (nonatomic, strong) NSString *customDeviceName;        // Device Name
@property (nonatomic, strong) NSString *customModel;             // Device Model
@property (nonatomic, strong) NSString *customProductType;       // Product Type (e.g., iPhone14,2)
@property (nonatomic, strong) NSString *customSystemVersion;     // iOS Version
@property (nonatomic, strong) NSString *customRegionInfo;        // Region Info

// Advertising Tracking
@property (nonatomic, assign) BOOL advertisingTrackingEnabled;

// Methods
- (void)generateRandomIDs;
- (void)resetToOriginal;
- (void)saveSettings;
- (void)loadSettings;
- (NSDictionary *)getCurrentValues;
- (void)setCustomValue:(NSString *)value forKey:(NSString *)key;

@end
