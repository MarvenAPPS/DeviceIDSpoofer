#import <UIKit/UIKit.h>
#import "DeviceIDManager.h"

@interface FloatingWindow : UIWindow

- (instancetype)initWithDeviceIDManager:(DeviceIDManager *)manager;
- (void)show;
- (void)hide;

@end
