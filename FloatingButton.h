#import <UIKit/UIKit.h>

@class DeviceIDManager;

@interface FloatingButton : NSObject

- (instancetype)initWithDeviceIDManager:(DeviceIDManager *)manager;
- (void)show;
- (void)hide;

@end
