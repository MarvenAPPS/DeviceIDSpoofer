#import "FloatingButton.h"
#import "DeviceIDManager.h"

@interface FloatingButton ()
@property (nonatomic, strong) UIWindow *floatingWindow;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) DeviceIDManager *deviceIDManager;
@property (nonatomic, assign) CGPoint lastLocation;
@property (nonatomic, assign) NSInteger tapCount;
@end

@implementation FloatingButton

- (instancetype)initWithDeviceIDManager:(DeviceIDManager *)manager {
    self = [super init];
    if (self) {
        _deviceIDManager = manager;
        _tapCount = 0;
    }
    return self;
}

- (void)show {
    if (self.floatingWindow) {
        NSLog(@"[FloatingButton] Window already exists");
        return;
    }
    
    NSLog(@"[FloatingButton] 🟢 Creating floating window...");
    
    // Create window ABOVE everything
    self.floatingWindow = [[UIWindow alloc] initWithFrame:CGRectMake(20, 100, 80, 80)];
    self.floatingWindow.windowLevel = UIWindowLevelAlert + 100;
    self.floatingWindow.backgroundColor = [UIColor clearColor];
    self.floatingWindow.userInteractionEnabled = YES;
    self.floatingWindow.hidden = NO;
    
    // Simple root view controller
    UIViewController *rootVC = [[UIViewController alloc] init];
    rootVC.view.backgroundColor = [UIColor clearColor];
    rootVC.view.userInteractionEnabled = YES;
    self.floatingWindow.rootViewController = rootVC;
    
    // Create button
    self.button = [UIButton buttonWithType:UIButtonTypeCustom];
    self.button.frame = CGRectMake(0, 0, 80, 80);
    self.button.userInteractionEnabled = YES;
    self.button.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.9];
    self.button.layer.cornerRadius = 40;
    self.button.layer.shadowColor = [UIColor blackColor].CGColor;
    self.button.layer.shadowOffset = CGSizeMake(0, 2);
    self.button.layer.shadowRadius = 4;
    self.button.layer.shadowOpacity = 0.3;
    
    // Main icon
    [self.button setTitle:@"🎮" forState:UIControlStateNormal];
    self.button.titleLabel.font = [UIFont systemFontOfSize:36];
    
    // Status label (shows profile number)
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 55, 80, 20)];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont boldSystemFontOfSize:12];
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.userInteractionEnabled = NO;
    [self.button addSubview:self.statusLabel];
    
    [self updateButtonAppearance];
    
    // Add tap action
    [self.button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // Add pan gesture for dragging
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.button addGestureRecognizer:panGesture];
    
    [rootVC.view addSubview:self.button];
    
    NSLog(@"[FloatingButton] ✅ Floating button created");
}

- (void)updateButtonAppearance {
    if (self.deviceIDManager.currentProfileIndex < 0) {
        // Disabled state
        self.button.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.9];
        self.statusLabel.text = @"OFF";
    } else {
        // Active profile state
        self.button.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.9];
        self.statusLabel.text = [NSString stringWithFormat:@"P%ld", (long)(self.deviceIDManager.currentProfileIndex + 1)];
    }
}

- (void)buttonTapped:(UIButton *)sender {
    _tapCount++;
    
    NSLog(@"[FloatingButton] 👆 Button tapped! Count: %ld", (long)_tapCount);
    
    // Switch to next profile
    [self.deviceIDManager switchToNextProfile];
    
    // Update button appearance
    [self updateButtonAppearance];
    
    // Show toast notification
    [self showToast];
    
    // Add visual feedback
    [UIView animateWithDuration:0.1 animations:^{
        self.button.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.button.transform = CGAffineTransformIdentity;
        }];
    }];
}

- (void)showToast {
    // Create toast label
    UILabel *toast = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 80)];
    toast.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.9];
    toast.textColor = [UIColor whiteColor];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.numberOfLines = 2;
    toast.font = [UIFont boldSystemFontOfSize:14];
    toast.layer.cornerRadius = 12;
    toast.clipsToBounds = YES;
    
    if (self.deviceIDManager.currentProfileIndex < 0) {
        toast.text = @"🔴 DISABLED\nOriginal IDFV";
    } else {
        toast.text = [NSString stringWithFormat:@"🟢 %@\n%@", 
                     [self.deviceIDManager getCurrentProfileName],
                     [[self.deviceIDManager getCurrentProfileIDFV] substringToIndex:8]];
    }
    
    // Center on screen
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    toast.center = CGPointMake(screenBounds.size.width / 2, screenBounds.size.height / 2);
    
    // Get key window - iOS 15+ compatible way
    UIWindow *keyWindow = nil;
    
    if (@available(iOS 15.0, *)) {
        // Modern approach for iOS 15+
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
                if (keyWindow) break;
            }
        }
        
        // Fallback: get first window
        if (!keyWindow) {
            for (UIScene *scene in connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    keyWindow = windowScene.windows.firstObject;
                    if (keyWindow) break;
                }
            }
        }
    } else {
        // Legacy approach for iOS 14 and below
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
        NSLog(@"[FloatingButton] ⚠️ No key window found for toast");
        return;
    }
    
    toast.alpha = 0;
    [keyWindow addSubview:toast];
    
    // Animate in and out
    [UIView animateWithDuration:0.3 animations:^{
        toast.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:1.5 options:0 animations:^{
            toast.alpha = 0;
        } completion:^(BOOL finished) {
            [toast removeFromSuperview];
        }];
    }];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.floatingWindow];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.lastLocation = self.floatingWindow.center;
    }
    
    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(
            self.lastLocation.x + translation.x,
            self.lastLocation.y + translation.y
        );
        
        // Keep within screen bounds
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        CGFloat margin = 40;
        newCenter.x = MAX(margin, MIN(screenBounds.size.width - margin, newCenter.x));
        newCenter.y = MAX(margin + 40, MIN(screenBounds.size.height - margin, newCenter.y));
        
        self.floatingWindow.center = newCenter;
    }
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        NSLog(@"[FloatingButton] Moved to: %@", NSStringFromCGPoint(self.floatingWindow.center));
    }
}

- (void)hide {
    NSLog(@"[FloatingButton] Hiding floating button");
    self.floatingWindow.hidden = YES;
    self.floatingWindow = nil;
    self.button = nil;
    self.statusLabel = nil;
}

@end
