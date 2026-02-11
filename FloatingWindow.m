#import "FloatingWindow.h"
#import "UIManager.h"

@interface FloatingWindow () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) UILabel *debugLabel;
@property (nonatomic, strong) DeviceIDManager *deviceIDManager;
@property (nonatomic, strong) UIManager *uiManager;
@property (nonatomic, assign) CGPoint lastTouchPoint;
@property (nonatomic, assign) NSInteger tapCount;

@end

@implementation FloatingWindow

- (instancetype)initWithDeviceIDManager:(DeviceIDManager *)manager {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    self = [super initWithFrame:screenBounds];
    
    if (self) {
        _deviceIDManager = manager;
        _uiManager = [[UIManager alloc] initWithDeviceIDManager:manager];
        _tapCount = 0;
        
        // Window configuration
        self.windowLevel = UIWindowLevelAlert + 100;
        self.backgroundColor = [UIColor clearColor];
        
        // Root view controller
        UIViewController *rootVC = [[UIViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        self.rootViewController = rootVC;
        
        [self setupFloatingButton];
        [self setupDebugLabel];
    }
    
    return self;
}

- (void)setupFloatingButton {
    CGFloat buttonSize = 60.0;
    CGFloat margin = 20.0;
    
    self.floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.floatingButton.frame = CGRectMake(
        self.bounds.size.width - buttonSize - margin,
        self.bounds.size.height / 2,
        buttonSize,
        buttonSize
    );
    
    // Style the button with BRIGHT color to make it obvious
    self.floatingButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0]; // Bright red
    self.floatingButton.layer.cornerRadius = buttonSize / 2;
    self.floatingButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.floatingButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.floatingButton.layer.shadowRadius = 8;
    self.floatingButton.layer.shadowOpacity = 0.5;
    self.floatingButton.layer.borderWidth = 3;
    self.floatingButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    // Add icon
    UILabel *iconLabel = [[UILabel alloc] initWithFrame:self.floatingButton.bounds];
    iconLabel.text = @"TAP\nME";
    iconLabel.numberOfLines = 2;
    iconLabel.textColor = [UIColor whiteColor];
    iconLabel.font = [UIFont boldSystemFontOfSize:14];
    iconLabel.textAlignment = NSTextAlignmentCenter;
    iconLabel.userInteractionEnabled = NO;
    [self.floatingButton addSubview:iconLabel];
    
    // Add tap gesture
    [self.floatingButton addTarget:self action:@selector(floatingButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    // Add pan gesture for dragging
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGesture.delegate = self;
    [self.floatingButton addGestureRecognizer:panGesture];
    
    [self.rootViewController.view addSubview:self.floatingButton];
    
    NSLog(@"[FloatingWindow] 🔴 RED BUTTON created at: %@", NSStringFromCGRect(self.floatingButton.frame));
}

- (void)setupDebugLabel {
    // Debug label to show tap count
    self.debugLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 50, 200, 40)];
    self.debugLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    self.debugLabel.textColor = [UIColor greenColor];
    self.debugLabel.font = [UIFont boldSystemFontOfSize:16];
    self.debugLabel.textAlignment = NSTextAlignmentCenter;
    self.debugLabel.text = @"Taps: 0";
    self.debugLabel.layer.cornerRadius = 8;
    self.debugLabel.clipsToBounds = YES;
    self.debugLabel.userInteractionEnabled = NO;
    [self.rootViewController.view addSubview:self.debugLabel];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.rootViewController.view];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.lastTouchPoint = self.floatingButton.center;
        NSLog(@"[FloatingWindow] 🔵 Pan began");
        
        // Visual feedback for drag
        self.floatingButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0]; // Blue while dragging
        
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(
            self.lastTouchPoint.x + translation.x,
            self.lastTouchPoint.y + translation.y
        );
        
        // Keep button within screen bounds
        CGFloat buttonRadius = self.floatingButton.bounds.size.width / 2;
        newCenter.x = MAX(buttonRadius, MIN(self.bounds.size.width - buttonRadius, newCenter.x));
        newCenter.y = MAX(buttonRadius, MIN(self.bounds.size.height - buttonRadius, newCenter.y));
        
        self.floatingButton.center = newCenter;
        
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        NSLog(@"[FloatingWindow] 🔵 Pan ended");
        self.floatingButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0]; // Back to red
        [self snapToNearestEdge];
    }
}

- (void)snapToNearestEdge {
    CGFloat margin = 20.0;
    CGFloat buttonRadius = self.floatingButton.bounds.size.width / 2;
    CGPoint center = self.floatingButton.center;
    
    CGFloat leftDistance = center.x;
    CGFloat rightDistance = self.bounds.size.width - center.x;
    
    CGFloat targetX = (leftDistance < rightDistance) ? (buttonRadius + margin) : (self.bounds.size.width - buttonRadius - margin);
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.floatingButton.center = CGPointMake(targetX, center.y);
    } completion:nil];
}

- (void)floatingButtonTapped {
    self.tapCount++;
    NSLog(@"[FloatingWindow] ✅✅✅ BUTTON TAPPED! Count: %ld", (long)self.tapCount);
    
    // Update debug label
    self.debugLabel.text = [NSString stringWithFormat:@"Taps: %ld", (long)self.tapCount];
    
    // VISUAL FEEDBACK - Flash bright green
    UIColor *originalColor = self.floatingButton.backgroundColor;
    self.floatingButton.backgroundColor = [UIColor colorWithRed:0.2 green:1.0 blue:0.3 alpha:1.0]; // Bright green
    
    // Haptic feedback
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
    [feedback impactOccurred];
    
    // Animate - flash and scale
    [UIView animateWithDuration:0.15 animations:^{
        self.floatingButton.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            self.floatingButton.transform = CGAffineTransformIdentity;
            self.floatingButton.backgroundColor = originalColor;
        }];
    }];
    
    // Show menu after visual feedback
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.uiManager showMenuFromWindow:self];
    });
}

- (void)show {
    self.hidden = NO;
    
    // Make window visible and key
    [self makeKeyAndVisible];
    
    NSLog(@"[FloatingWindow] 🟢 Window shown - makeKeyAndVisible called");
    NSLog(@"[FloatingWindow] Window level: %f", (double)self.windowLevel);
    NSLog(@"[FloatingWindow] Is key window: %@", self.isKeyWindow ? @"YES" : @"NO");
    
    // Animate button appearance
    self.floatingButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
    self.floatingButton.alpha = 0;
    self.debugLabel.alpha = 0;
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.floatingButton.transform = CGAffineTransformIdentity;
        self.floatingButton.alpha = 1.0;
        self.debugLabel.alpha = 1.0;
    } completion:^(BOOL finished) {
        NSLog(@"[FloatingWindow] ✅ Button animation complete and ready");
    }];
}

- (void)hide {
    [UIView animateWithDuration:0.2 animations:^{
        self.floatingButton.alpha = 0;
        self.debugLabel.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

#pragma mark - Touch Handling

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog(@"[FloatingWindow] 🔍 hitTest called at point: %@", NSStringFromCGPoint(point));
    
    if (self.hidden || !self.userInteractionEnabled) {
        NSLog(@"[FloatingWindow] ❌ Window hidden or disabled");
        return nil;
    }
    
    // Check if touch is within button's frame
    CGPoint pointInButton = [self.floatingButton convertPoint:point fromView:self];
    
    if ([self.floatingButton pointInside:pointInButton withEvent:event]) {
        NSLog(@"[FloatingWindow] ✅✅ TOUCH ON BUTTON DETECTED!");
        return self.floatingButton;
    }
    
    NSLog(@"[FloatingWindow] ⚪ Touch passed through");
    return nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

@end
