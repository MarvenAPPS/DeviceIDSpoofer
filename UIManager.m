#import "UIManager.h"

@interface UIManager () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) DeviceIDManager *deviceIDManager;
@property (nonatomic, strong) UIViewController *menuViewController;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSString *> *deviceIDKeys;
@property (nonatomic, strong) UISwitch *masterSwitch;

@end

@implementation UIManager

- (instancetype)initWithDeviceIDManager:(DeviceIDManager *)manager {
    self = [super init];
    if (self) {
        _deviceIDManager = manager;
        _deviceIDKeys = @[
            @"IDFV",
            @"IDFA",
            @"UDID",
            @"Serial Number",
            @"WiFi MAC",
            @"Bluetooth MAC",
            @"Device Name",
            @"Model",
            @"Product Type",
            @"System Version",
            @"Region Info"
        ];
    }
    return self;
}

- (void)showMenuFromWindow:(UIWindow *)window {
    if (self.menuViewController) {
        NSLog(@"[UIManager] Menu already shown, dismissing...");
        [self dismissMenu];
        return;
    }
    
    NSLog(@"[UIManager] 🟢 Creating menu...");
    
    self.menuViewController = [[UIViewController alloc] init];
    self.menuViewController.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.menuViewController.view.userInteractionEnabled = YES; // CRITICAL
    self.menuViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    // Create container view
    self.containerView = [[UIView alloc] initWithFrame:CGRectMake(
        20,
        100,
        window.bounds.size.width - 40,
        window.bounds.size.height - 200
    )];
    self.containerView.backgroundColor = [UIColor colorWithRed:1.0 green:0.98 blue:0.95 alpha:1.0]; // Slight cream color
    self.containerView.userInteractionEnabled = YES; // CRITICAL
    self.containerView.layer.cornerRadius = 15;
    self.containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.containerView.layer.shadowOffset = CGSizeMake(0, 4);
    self.containerView.layer.shadowRadius = 10;
    self.containerView.layer.shadowOpacity = 0.3;
    [self.menuViewController.view addSubview:self.containerView];
    
    // Header
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.containerView.bounds.size.width, 100)];
    headerView.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0];
    headerView.userInteractionEnabled = YES;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, headerView.bounds.size.width - 40, 30)];
    titleLabel.text = @"Device ID Spoofer";
    titleLabel.font = [UIFont boldSystemFontOfSize:22];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.userInteractionEnabled = NO;
    [headerView addSubview:titleLabel];
    
    // Master switch
    UILabel *switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 55, 150, 30)];
    switchLabel.text = @"Enable Spoofing";
    switchLabel.font = [UIFont systemFontOfSize:16];
    switchLabel.textColor = [UIColor whiteColor];
    switchLabel.userInteractionEnabled = NO;
    [headerView addSubview:switchLabel];
    
    self.masterSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    self.masterSwitch.on = self.deviceIDManager.isEnabled;
    self.masterSwitch.userInteractionEnabled = YES;
    [self.masterSwitch addTarget:self action:@selector(masterSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.masterSwitch.center = CGPointMake(headerView.bounds.size.width - 50, 70);
    [headerView addSubview:self.masterSwitch];
    
    [self.containerView addSubview:headerView];
    
    // Action buttons
    UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(
        0,
        100,
        self.containerView.bounds.size.width,
        60
    )];
    buttonContainer.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0];
    buttonContainer.userInteractionEnabled = YES;
    
    UIButton *generateButton = [self createButtonWithTitle:@"🎲 Generate" action:@selector(generateIDs)];
    generateButton.frame = CGRectMake(10, 10, (buttonContainer.bounds.size.width - 30) / 2, 40);
    [buttonContainer addSubview:generateButton];
    
    UIButton *resetButton = [self createButtonWithTitle:@"🔄 Reset" action:@selector(resetIDs)];
    resetButton.frame = CGRectMake(CGRectGetMaxX(generateButton.frame) + 10, 10, (buttonContainer.bounds.size.width - 30) / 2, 40);
    resetButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0];
    [buttonContainer addSubview:resetButton];
    
    [self.containerView addSubview:buttonContainer];
    
    // Table view
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(
        0,
        160,
        self.containerView.bounds.size.width,
        self.containerView.bounds.size.height - 210
    ) style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.userInteractionEnabled = YES; // CRITICAL
    [self.containerView addSubview:self.tableView];
    
    // Close button - LARGER and more obvious
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(
        self.containerView.bounds.size.width - 60,
        self.containerView.bounds.size.height - 60,
        50,
        50
    )];
    closeButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0];
    closeButton.layer.cornerRadius = 25;
    closeButton.userInteractionEnabled = YES;
    [closeButton setTitle:@"✕" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:28];
    [closeButton addTarget:self action:@selector(dismissMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:closeButton];
    
    NSLog(@"[UIManager] Close button created at: %@", NSStringFromCGRect(closeButton.frame));
    
    // Tap gesture to dismiss (on background only)
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
    [self.menuViewController.view addGestureRecognizer:tapGesture];
    
    // Present
    NSLog(@"[UIManager] Presenting menu view controller...");
    [window.rootViewController presentViewController:self.menuViewController animated:YES completion:^{
        NSLog(@"[UIManager] ✅ Menu presented successfully");
    }];
}

- (UIButton *)createButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.userInteractionEnabled = YES;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0];
    button.layer.cornerRadius = 8;
    button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    
    NSLog(@"[UIManager] Created button: %@", title);
    return button;
}

- (void)backgroundTapped:(UITapGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self.menuViewController.view];
    NSLog(@"[UIManager] Background tapped at: %@", NSStringFromCGPoint(location));
    
    // Check if tap is outside container
    if (!CGRectContainsPoint(self.containerView.frame, location)) {
        NSLog(@"[UIManager] Tap outside container, dismissing...");
        [self dismissMenu];
    } else {
        NSLog(@"[UIManager] Tap inside container, ignoring");
    }
}

- (void)dismissMenu {
    NSLog(@"[UIManager] 🔴 Dismissing menu...");
    [self.menuViewController dismissViewControllerAnimated:YES completion:^{
        NSLog(@"[UIManager] ✅ Menu dismissed");
        self.menuViewController = nil;
        self.tableView = nil;
        self.containerView = nil;
    }];
}

- (void)masterSwitchChanged:(UISwitch *)sender {
    NSLog(@"[UIManager] ✅ Master switch toggled: %@", sender.on ? @"ON" : @"OFF");
    self.deviceIDManager.isEnabled = sender.on;
    [self.deviceIDManager saveSettings];
    [self.tableView reloadData];
}

- (void)generateIDs {
    NSLog(@"[UIManager] ✅ Generate button tapped");
    [self.deviceIDManager generateRandomIDs];
    [self.tableView reloadData];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success" 
                                                                   message:@"New device IDs generated" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self.menuViewController presentViewController:alert animated:YES completion:nil];
}

- (void)resetIDs {
    NSLog(@"[UIManager] ✅ Reset button tapped");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Reset IDs" 
                                                                   message:@"This will reset all IDs to original values" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self.deviceIDManager resetToOriginal];
        self.masterSwitch.on = NO;
        [self.tableView reloadData];
    }]];
    
    [self.menuViewController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.deviceIDKeys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"DeviceIDCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.userInteractionEnabled = YES;
    }
    
    NSString *key = self.deviceIDKeys[indexPath.row];
    NSDictionary *currentValues = [self.deviceIDManager getCurrentValues];
    NSString *value = currentValues[key];
    
    cell.textLabel.text = key;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
    cell.detailTextLabel.text = value;
    cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    // Color code cells
    cell.backgroundColor = [UIColor colorWithRed:0.95 green:0.98 blue:1.0 alpha:1.0];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSLog(@"[UIManager] ✅ Table row tapped: %ld", (long)indexPath.row);
    
    NSString *key = self.deviceIDKeys[indexPath.row];
    NSDictionary *currentValues = [self.deviceIDManager getCurrentValues];
    NSString *currentValue = currentValues[key];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Edit %@", key]
                                                                   message:@"Enter custom value"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = currentValue;
        textField.placeholder = @"Enter value";
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alert.textFields.firstObject;
        if (textField.text.length > 0) {
            [self.deviceIDManager setCustomValue:textField.text forKey:key];
            [self.tableView reloadData];
        }
    }]];
    
    [self.menuViewController presentViewController:alert animated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

@end
