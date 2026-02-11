#import <Foundation/Foundation.h>

@interface DeviceIDManager : NSObject

@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, assign) NSInteger currentProfileIndex; // 0-9 for profiles, -1 for disabled

+ (instancetype)sharedManager;

// Profile management
- (void)switchToNextProfile;
- (NSString *)getCurrentProfileName;
- (NSString *)getCurrentProfileIDFV;

// Legacy methods (for UI if needed later)
- (void)generateRandomIDs;
- (void)resetToOriginal;
- (NSDictionary *)getCurrentValues;
- (void)setCustomValue:(NSString *)value forKey:(NSString *)key;
- (void)saveSettings;
- (void)loadSettings;

@end
