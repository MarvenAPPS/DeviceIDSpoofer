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
        
        // CRITICAL: Window configuration for proper touch handling
        self.windowLevel = UIWindowLevelAlert + 100;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES; // Enable touches
        self.opaque = NO; // Transparent background
        
        // Root view controller with transparent view
        UIViewController *rootVC = [[UIViewController alloc] init];
        rootVC.view.backgroundColor = [UIColor clearColor];
        rootVC.view.userInteractionEnabled = YES;
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
    
    // CRITICAL: Enable interaction on button
    self.floatingButton.userInteractionEnabled = YES;
    
    // Style the button
    self.floatingButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.9];
    self.floatingButton.layer.cornerRadius = buttonSize / 2;
    self.floatingButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.floatingButton.layer.shadowOffset = CGSizeMake(0, 2);
    self.floatingButton.layer.shadowRadius = 4;
    self.floatingButton.layer.shadowOpacity = 0.3;
    
    // Add icon
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 15, 30, 30)];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.tintColor = [UIColor whiteColor];
    iconView.userInteractionEnabled = NO; // Don't block touches
    
    // Create a simple "ID" icon using a label
    UILabel *iconLabel = [[UILabel alloc] initWithFrame:iconView.bounds];
    iconLabel.text = @"ID";
    iconLabel.textColor = [UIColor whiteColor];
    iconLabel.font = [UIFont boldSystemFontOfSize:18];
    iconLabel.textAlignment = NSTextAlignmentCenter;
    iconLabel.userInteractionEnabled = NO; // Don't block touches
    [iconView addSubview:iconLabel];
    
    [self.floatingButton addSubview:iconView];
    
    // Add tap gesture
    [self.floatingButton addTarget:self action:@selector(floatingButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    // Add pan gesture for dragging
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGesture.delegate = self;
    [self.floatingButton addGestureRecognizer:panGesture];
    
    [self.rootViewController.view addSubview:self.floatingButton];
    
    NSLog(@"[FloatingWindow] Button created at: %@", NSStringFromCGRect(self.floatingButton.frame));
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self];
    
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
        NSLog(@"[FloatingWindow] Pan ended, snapping to edge");
        // Snap to nearest edge
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
    NSLog(@"[FloatingWindow] Button tapped!");
    [self.uiManager showMenuFromWindow:self];
}

- (void)show {
    self.hidden = NO;
    [self makeKeyAndVisible]; // CRITICAL: Make window visible and active
    
    // Animate button appearance
    self.floatingButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
    self.floatingButton.alpha = 0;
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.floatingButton.transform = CGAffineTransformIdentity;
        self.floatingButton.alpha = 1.0;
    } completion:^(BOOL finished) {
        NSLog(@"[FloatingWindow] Button shown and ready");
    }];
}

- (void)hide {
    [UIView animateWithDuration:0.2 animations:^{
        self.floatingButton.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

// CRITICAL: Hit test override to only capture touches on button
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // Convert point to root view controller's view coordinate space
    CGPoint buttonPoint = [self.rootViewController.view convertPoint:point fromView:self];
    
    // Check if touch is within button bounds
    if (CGRectContainsPoint(self.floatingButton.frame, buttonPoint)) {
        NSLog(@"[FloatingWindow] Hit test: Touch on button");
        return [self.floatingButton hitTest:[self.floatingButton convertPoint:point fromView:self] withEvent:event];
    }
    
    // Let touches pass through to app behind
    return nil;
}

// Deprecated method - keep for compatibility
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // Only respond to touches on the floating button
    CGPoint buttonPoint = [self.rootViewController.view convertPoint:point fromView:self];
    return CGRectContainsPoint(self.floatingButton.frame, buttonPoint);
}

@end
