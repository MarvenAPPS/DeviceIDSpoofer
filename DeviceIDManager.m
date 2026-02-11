#import "DeviceIDManager.h"

static NSString *const kEnabledKey = @"DeviceIDSpoofingEnabled";
static NSString *const kCurrentProfileKey = @"CurrentProfileIndex";

// 10 Predefined IDFV profiles
static NSDictionary *profiles = nil;

@interface DeviceIDManager ()
@property (nonatomic, strong) NSMutableDictionary *customValues;
@property (nonatomic, strong) NSDictionary *originalValues;
@end

@implementation DeviceIDManager

+ (instancetype)sharedManager {
    static DeviceIDManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize 10 predefined profiles
        profiles = @{
            @"Profile 1: Gaming": @"12345678-AAAA-BBBB-CCCC-111111111111",
            @"Profile 2: Social": @"87654321-BBBB-CCCC-DDDD-222222222222",
            @"Profile 3: Finance": @"ABCDEFAB-CCCC-DDDD-EEEE-333333333333",
            @"Profile 4: Shopping": @"FEDCBAFE-DDDD-EEEE-FFFF-444444444444",
            @"Profile 5: Media": @"11111111-EEEE-FFFF-0000-555555555555",
            @"Profile 6: Work": @"22222222-FFFF-0000-1111-666666666666",
            @"Profile 7: Testing": @"33333333-0000-1111-2222-777777777777",
            @"Profile 8: Privacy": @"44444444-1111-2222-3333-888888888888",
            @"Profile 9: Development": @"55555555-2222-3333-4444-999999999999",
            @"Profile 10: Default": @"66666666-3333-4444-5555-AAAAAAAAAAAA"
        };
        
        _customValues = [NSMutableDictionary dictionary];
        _originalValues = @{};
        
        [self loadSettings];
    }
    return self;
}

#pragma mark - Profile Management

- (void)switchToNextProfile {
    // Cycle: -1 (disabled) -> 0 -> 1 -> ... -> 9 -> -1 (disabled)
    _currentProfileIndex++;
    
    if (_currentProfileIndex >= 10) {
        // After profile 9, go back to disabled
        _currentProfileIndex = -1;
        _isEnabled = NO;
        NSLog(@"[DeviceIDManager] 🔴 Profile cycling complete - DISABLED");
    } else {
        // Enable spoofing with new profile
        _isEnabled = YES;
        NSLog(@"[DeviceIDManager] 🟢 Switched to profile %ld: %@ -> %@", 
              (long)_currentProfileIndex, 
              [self getCurrentProfileName],
              [self getCurrentProfileIDFV]);
    }
    
    [self saveSettings];
}

- (NSString *)getCurrentProfileName {
    if (_currentProfileIndex < 0 || _currentProfileIndex >= 10) {
        return @"Disabled";
    }
    
    NSArray *profileNames = @[
        @"Profile 1: Gaming",
        @"Profile 2: Social",
        @"Profile 3: Finance",
        @"Profile 4: Shopping",
        @"Profile 5: Media",
        @"Profile 6: Work",
        @"Profile 7: Testing",
        @"Profile 8: Privacy",
        @"Profile 9: Development",
        @"Profile 10: Default"
    ];
    
    return profileNames[_currentProfileIndex];
}

- (NSString *)getCurrentProfileIDFV {
    if (_currentProfileIndex < 0 || _currentProfileIndex >= 10) {
        return @"Original IDFV";
    }
    
    NSString *profileName = [self getCurrentProfileName];
    return profiles[profileName];
}

#pragma mark - Settings

- (void)saveSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:_isEnabled forKey:kEnabledKey];
    [defaults setInteger:_currentProfileIndex forKey:kCurrentProfileKey];
    [defaults synchronize];
    
    NSLog(@"[DeviceIDManager] 💾 Settings saved - Profile: %ld, Enabled: %@", 
          (long)_currentProfileIndex, _isEnabled ? @"YES" : @"NO");
}

- (void)loadSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _isEnabled = [defaults boolForKey:kEnabledKey];
    _currentProfileIndex = [defaults integerForKey:kCurrentProfileKey];
    
    // If never set, default to Profile 1 (Gaming) - ENABLED
    if (![defaults objectForKey:kCurrentProfileKey]) {
        _currentProfileIndex = 0;  // Profile 1
        _isEnabled = YES;          // Enabled by default
        [self saveSettings];       // Save this default immediately
        NSLog(@"[DeviceIDManager] 🟢 First launch - Profile 1 ENABLED by default");
    }
    
    NSLog(@"[DeviceIDManager] 📂 Settings loaded - Profile: %ld, Enabled: %@", 
          (long)_currentProfileIndex, _isEnabled ? @"YES" : @"NO");
}

#pragma mark - Legacy Methods (for UI)

- (void)generateRandomIDs {
    // Generate random UUIDs
    NSUUID *uuid = [NSUUID UUID];
    [_customValues setObject:uuid.UUIDString forKey:@"IDFV"];
    [_customValues setObject:[NSUUID UUID].UUIDString forKey:@"IDFA"];
    [_customValues setObject:[NSUUID UUID].UUIDString forKey:@"UDID"];
    
    NSLog(@"[DeviceIDManager] Random IDs generated");
}

- (void)resetToOriginal {
    [_customValues removeAllObjects];
    _isEnabled = NO;
    _currentProfileIndex = -1;
    [self saveSettings];
    NSLog(@"[DeviceIDManager] Reset to original values");
}

- (NSDictionary *)getCurrentValues {
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    
    // Show current profile IDFV if active
    if (_isEnabled && _currentProfileIndex >= 0 && _currentProfileIndex < 10) {
        values[@"IDFV"] = [self getCurrentProfileIDFV];
    } else {
        values[@"IDFV"] = @"Original IDFV";
    }
    
    // Placeholder for other values
    values[@"IDFA"] = _customValues[@"IDFA"] ?: @"Original IDFA";
    values[@"UDID"] = _customValues[@"UDID"] ?: @"Original UDID";
    values[@"Serial Number"] = @"C02XYZ123ABC";
    values[@"WiFi MAC"] = @"00:11:22:33:44:55";
    values[@"Bluetooth MAC"] = @"AA:BB:CC:DD:EE:FF";
    values[@"Device Name"] = @"iPhone";
    values[@"Model"] = @"iPhone14,2";
    values[@"Product Type"] = @"iPhone14,2";
    values[@"System Version"] = @"17.0";
    values[@"Region Info"] = @"US";
    
    return values;
}

- (void)setCustomValue:(NSString *)value forKey:(NSString *)key {
    [_customValues setObject:value forKey:key];
    NSLog(@"[DeviceIDManager] Custom value set: %@ = %@", key, value);
}

@end
