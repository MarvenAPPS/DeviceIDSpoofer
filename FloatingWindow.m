#import "FloatingWindow.h"
#import "UIManager.h"

@interface FloatingWindow () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) DeviceIDManager *deviceIDManager;
@property (nonatomic, strong) UIManager *uiManager;
@property (nonatomic, assign) CGPoint lastTouchPoint;

@end

@implementation FloatingWindow

- (instancetype)initWithDeviceIDManager:(DeviceIDManager *)manager {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    self = [super initWithFrame:screenBounds];
    
    if (self) {
        _deviceIDManager = manager;
        _uiManager = [[UIManager alloc] initWithDeviceIDManager:manager];
        
        // Window configuration
        self.windowLevel = UIWindowLevelAlert + 100;
        self.backgroundColor = [UIColor clearColor];
        
        // Root view controller
        UIViewController *rootVC = [[UIViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        self.rootViewController = rootVC;
        
        [self setupFloatingButton];
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
    
    // Style the button
    self.floatingButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.9];
    self.floatingButton.layer.cornerRadius = buttonSize / 2;
    self.floatingButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.floatingButton.layer.shadowOffset = CGSizeMake(0, 2);
    self.floatingButton.layer.shadowRadius = 4;
    self.floatingButton.layer.shadowOpacity = 0.3;
    
    // Add icon
    UILabel *iconLabel = [[UILabel alloc] initWithFrame:self.floatingButton.bounds];
    iconLabel.text = @"ID";
    iconLabel.textColor = [UIColor whiteColor];
    iconLabel.font = [UIFont boldSystemFontOfSize:18];
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
    
    NSLog(@"[FloatingWindow] Button setup complete at: %@", NSStringFromCGRect(self.floatingButton.frame));
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.rootViewController.view];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.lastTouchPoint = self.floatingButton.center;
        NSLog(@"[FloatingWindow] Pan began");
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
        NSLog(@"[FloatingWindow] Pan ended");
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
    NSLog(@"[FloatingWindow] ✅ Button tapped!");
    
    // Haptic feedback
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [feedback impactOccurred];
    
    // Animate tap
    [UIView animateWithDuration:0.1 animations:^{
        self.floatingButton.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.floatingButton.transform = CGAffineTransformIdentity;
        }];
    }];
    
    [self.uiManager showMenuFromWindow:self];
}

- (void)show {
    self.hidden = NO;
    
    // Make window visible and key (important for touch events)
    [self makeKeyAndVisible];
    
    // Animate button appearance
    self.floatingButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
    self.floatingButton.alpha = 0;
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.floatingButton.transform = CGAffineTransformIdentity;
        self.floatingButton.alpha = 1.0;
    } completion:^(BOOL finished) {
        NSLog(@"[FloatingWindow] Window shown and ready for touches");
    }];
}

- (void)hide {
    [UIView animateWithDuration:0.2 animations:^{
        self.floatingButton.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

#pragma mark - Touch Handling (CRITICAL)

// This is the KEY method - it determines what receives touches
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // If window is hidden or interaction disabled, pass through
    if (self.hidden || !self.userInteractionEnabled) {
        return nil;
    }
    
    // Check if touch is within button's frame
    CGPoint pointInButton = [self.floatingButton convertPoint:point fromView:self];
    
    if ([self.floatingButton pointInside:pointInButton withEvent:event]) {
        NSLog(@"[FloatingWindow] ✅ Touch detected on button at: %@", NSStringFromCGPoint(point));
        // Return the button - it will handle the touch
        return self.floatingButton;
    }
    
    // Touch is outside button - pass through to app behind
    NSLog(@"[FloatingWindow] Touch passed through at: %@", NSStringFromCGPoint(point));
    return nil;
}

// Gesture recognizer delegate - allow simultaneous recognition
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO; // Don't allow simultaneous - button should capture exclusively
}

@end
