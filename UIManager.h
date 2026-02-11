#import <UIKit/UIKit.h>
#import "DeviceIDManager.h"

@interface UIManager : NSObject

- (instancetype)initWithDeviceIDManager:(DeviceIDManager *)manager;
- (void)showMenuFromWindow:(UIWindow *)window;

@end
