//
//  AppDelegate.m
//  Blockchain
//
//  Created by Ben Reeves on 05/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"
#import "TransactionsViewController.h"
#import "MultiAddressResponse.h"
#import "Wallet.h"
#import "BCFadeView.h"
#import "TabViewController.h"
#import "ReceiveCoinsViewController.h"
#import "SendViewController.h"
#import "AccountViewController.h"
#import "TransactionsViewController.h"
#import "WebViewController.h"
#import "NewAccountView.h"
#import "NSString+SHA256.h"
#import "Transaction.h"
#import "Input.h"
#import "Output.h"
#import "UIDevice+Hardware.h"
#import "UncaughtExceptionHandler.h"
#import "UITextField+Blocks.h"
#import "UIAlertView+Blocks.h"
#import "PairingCodeParser.h"
#import "PrivateKeyReader.h"
#import "MerchantViewController.h"

AppDelegate * app;

@implementation AppDelegate

@synthesize window = _window;
@synthesize wallet;
@synthesize modalView;
@synthesize latestResponse;


#pragma mark - Lifecycle

-(id)init {
    if (self = [super init]) {
        self.btcFormatter = [[NSNumberFormatter alloc] init];
        [_btcFormatter setMaximumFractionDigits:5];
        [_btcFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        
        self.localCurrencyFormatter = [[NSNumberFormatter alloc] init];
        [_localCurrencyFormatter setMaximumFractionDigits:2];
        [_localCurrencyFormatter setNumberStyle:NSNumberFormatterDecimalStyle];

        self.modalChain = [[NSMutableArray alloc] init];
        
        app = self;
        
    }
    return self;
}


- (void)installUncaughtExceptionHandler
{
	InstallUncaughtExceptionHandler();
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
//    unsigned int x;
//    unsigned int y;
//    zbar_version(&x, &y);
//    DLog(@"zbar version: %d %d", x, y);
    
    
    //Allocate the global wallet
    self.wallet = [[Wallet alloc] init];
    
    self.wallet.delegate = self;
    
    [self performSelector:@selector(installUncaughtExceptionHandler) withObject:nil afterDelay:0];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:LOADING_TEXT_NOTIFICAITON_KEY object:nil queue:nil usingBlock:^(NSNotification * notification) {
        
        self.loadingText = [notification object];
    }];
    
    // Override point for customization after application launch.
    _window.backgroundColor = [UIColor whiteColor];
    
    [_window makeKeyAndVisible];
    
    [_window setRootViewController:_tabViewController];
    
    [_tabViewController setActiveViewController:_transactionsViewController];

    [_window.rootViewController.view addSubview:busyView];
    
    busyView.frame = _window.frame;
    busyView.alpha = 0.0f;

    if ([self guid]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showPinModal];
        });
    }
    
    if (![self guid] || ![self sharedKey]) {
        [self showWelcome];
    } else if (![self password]) {
        [self showModal:mainPasswordView isClosable:FALSE];
    } else {
        
        NSString * guid = [self guid];
        NSString * sharedKey = [self sharedKey];
        NSString * password = [self password];
        
//        DLog(@"didFinishLaunchingWithOptions GUID %@", guid);
        
        if (guid && sharedKey && password) {
            [self.wallet loadGuid:guid sharedKey:sharedKey password:password];
        }
    }

    return TRUE;
}

- (void)transitionToIndex:(NSInteger)newIndex
{
    if (newIndex == 0)
        [self transactionsClicked:nil];
    else if (newIndex == 1)
        [self receiveCoinClicked:nil];
    else if (newIndex == 2)
        [self sendCoinsClicked:nil];
    else if (newIndex == 3)
        [self merchantClicked:nil];
    else
        DLog(@"Unknown tab index: %d", newIndex);
}

- (void)swipeLeft
{    
    if (_tabViewController.selectedIndex < 3)
    {
        NSInteger newIndex = _tabViewController.selectedIndex + 1;
        [self transitionToIndex:newIndex];
    }
}

- (void)swipeRight
{
    if (_tabViewController.selectedIndex)
    {
        NSInteger newIndex = _tabViewController.selectedIndex - 1;
        [self transitionToIndex:newIndex];
    }
}

-(IBAction)balanceTextClicked:(id)sender {
    [self toggleSymbol];
}

#pragma mark - UI State
-(void)toggleSymbol {
    symbolLocal = !symbolLocal;
    
    [_transactionsViewController reload];
    [_sendViewController reload];
    [_receiveViewController reload];
}



-(void)setDisableBusyView:(BOOL)__disableBusyView {
    _disableBusyView = __disableBusyView;
    
    if (_disableBusyView) {
        [busyView removeFromSuperview];
    }
    else {
        [_window.rootViewController.view addSubview:busyView];
//        [_window bringSubviewToFront:busyView];
    }
}

-(void)didWalletDecryptStart:(Wallet*)wallet {
    [self networkActivityStart];
}

-(void)didWalletDecryptSuccess:(Wallet*)wallet {
    [self networkActivityStop];
}


-(void)networkActivityStart {
    [busyView fadeIn];

    [powerButton setEnabled:FALSE];

    if (self.loadingText) {
        [busyLabel setText:self.loadingText];
    }
    
    [self setStatus];
}

-(void)networkActivityStop {
    [powerButton setEnabled:TRUE];

    [busyView fadeOut];
    
    [activity stopAnimating];
    
    [self setStatus];
}

-(void)setStatus {
    if ([app.wallet getWebsocketReadyState] != 1) {
        [powerButton setHighlighted:TRUE];
    } else {
        [powerButton setHighlighted:FALSE];
    }
}

#pragma mark - AlertView Helpers

- (void)standardNotify:(NSString*)message
{
	[self standardNotify:message title:@"Error" delegate:nil];
}

- (void)standardNotify:(NSString*)message delegate:(id)fdelegate
{
	[self standardNotify:message title:@"Error" delegate:fdelegate];
}

- (void)standardNotify:(NSString*)message title:(NSString*)title delegate:(id)fdelegate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message  delegate:fdelegate cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alert show];
        }
    });
}

-(void)didGenerateNewWallet:(Wallet*)_wallet password:(NSString*)password {
    
    [self forgetWallet];
    
    [[NSUserDefaults standardUserDefaults] setObject:wallet.guid forKey:@"guid"];
    [[NSUserDefaults standardUserDefaults] setObject:wallet.sharedKey forKey:@"sharedKey"];
    [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)walletDidLoad:(Wallet *)_wallet {      
    DLog(@"walletDidLoad");
    
    [self transitionToIndex:0];

    [self setAccountData:wallet.guid sharedKey:wallet.sharedKey password:wallet.password];
    
    [_transactionsViewController reload];
    [_receiveViewController reload];
    [_sendViewController reload];
    
    [app closeModal];
}

-(void)didGetMultiAddressResponse:(MulitAddressResponse*)response {
    self.latestResponse = response;

    _transactionsViewController.data = response;
    
    [_transactionsViewController reload];
    [_receiveViewController reload];
    [_sendViewController reload];
}

-(void)didSetLatestBlock:(LatestBlock*)block {
    _transactionsViewController.latestBlock = block;
}

-(void)walletFailedToDecrypt:(Wallet*)_wallet {    
    
    if ([self guid]) {
        self.wallet.password = nil;
        
        //Clear the password and refetch the wallet data
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"password"];
        
        [self showModal:mainPasswordView isClosable:FALSE];
        
        [mainPasswordTextField becomeFirstResponder];
    } else {
        //Called when bad password is entered when maually pairing
        [app showWelcome];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    if ([self guid]) {
        [self showPinModal];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    if (![self guid] || ![self sharedKey]) {
        [app showWelcome];
        return;
    }
    
    if (!wallet.password) {
        [self walletFailedToDecrypt:wallet];
    }

    [self.wallet getWalletAndHistory];
}

-(void)playBeepSound {
    
	if (beepSoundID == 0) {
		AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"]], &beepSoundID);
	}
	
	AudioServicesPlaySystemSound(beepSoundID);		
}

-(void)playAlertSound {
    
	if (alertSoundID == 0) {
		//Find the Alert Sound
		NSString * alert_sound = [[NSBundle mainBundle] pathForResource:@"alert-received" ofType:@"wav"];
		
		//Create the system sound
		AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: alert_sound], &alertSoundID);
	}
	
	AudioServicesPlaySystemSound(alertSoundID);		
}


// Only gets called when displaying a transaction hash
-(void)pushWebViewController:(NSString*)url {
    self.webViewController = [[WebViewController alloc] init];
    
    [_tabViewController setActiveViewController:_webViewController animated:YES index:-1];

    [_webViewController loadURL:url];
}

- (NSMutableDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:6];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        if ([elements count] >= 2) {
            NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            [dict setObject:val forKey:key];
        }
    }
    return dict;
}

-(NSDictionary*)parseURI:(NSString*)urlString {
    
    if (![urlString hasPrefix:@"bitcoin:"]) {
        return [NSDictionary dictionaryWithObject:urlString forKey:@"address"];
    }
        
    NSString * replaced = [[urlString stringByReplacingOccurrencesOfString:@"bitcoin:" withString:@"bitcoin://"] stringByReplacingOccurrencesOfString:@"////" withString:@"//"];
    
    NSURL * url = [NSURL URLWithString:replaced];
    
    NSMutableDictionary *dict = [self parseQueryString:[url query]];

    if ([url host] != NULL)
        [dict setObject:[url host] forKey:@"address"];
    
    return dict;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    [app closeModal];
    
    NSDictionary *dict = [self parseURI:[url absoluteString]];
        
    NSString * addr = [dict objectForKey:@"address"];
    NSString * amount = [dict objectForKey:@"amount"];

    [self showSendCoins];
    
    [_sendViewController setToAddressFromUrlHandler:addr];
    [_sendViewController setAmountFromUrlHandler:amount];

    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
    
    return YES;
}

-(void)getPrivateKeyPassword:(void (^)(NSString *))success error:(void (^)(NSString *))error {
    
    validateSecondPassword = FALSE;
    
    secondPasswordDescriptionLabel.text = @"The private key you are attempting to import is encrypted. Please enter the password below.";

    [app showModal:secondPasswordView isClosable:TRUE onDismiss:^() {
        NSString * password = secondPasswordTextField.text;
        
        if ([password length] == 0) {
            if (error) error(@"No Password Entered");
        } else {
            if (success) success(password);
        }
        
        secondPasswordTextField.text = nil;
    } onResume:nil];
    
    [secondPasswordTextField becomeFirstResponder];
}

-(IBAction)secondPasswordClicked:(id)sender {
    NSString * password = secondPasswordTextField.text;
    
    if (!validateSecondPassword || [wallet validateSecondPassword:password]) {
        [app closeModal];
    } else {
        [app standardNotify:@"Second Password Incorrect"];
        secondPasswordTextField.text = nil;
    }
}

-(void)getSecondPassword:(void (^)(NSString *))success error:(void (^)(NSString *))error {
    
    secondPasswordDescriptionLabel.text = @"This action requires the second password for your bitcoin wallet. Please enter it below and press continue.";
    
    validateSecondPassword = TRUE;
    
    [app showModal:secondPasswordView isClosable:TRUE onDismiss:^() {
        NSString * password = secondPasswordTextField.text;
                    
        if ([password length] == 0) {
            if (error) error(@"No Password Entered");
        } else if(![wallet validateSecondPassword:password]) {
            if (error) error(@"Second Password Incorrect");
        } else {
            if (success) success(password);
        }
        
        secondPasswordTextField.text = nil;
    } onResume:nil];
    
    [secondPasswordTextField becomeFirstResponder];
}


-(void)closeModal {
    [modalView removeFromSuperview];
    
    CATransition *animation = [CATransition animation];
    [animation setDuration:ANIMATION_DURATION];
    [animation setType:kCATransitionFade];
    
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [[_window layer] addAnimation:animation forKey:@"HideModal"];
    
    if (self.modalView.onDismiss) {
        self.modalView.onDismiss();
        self.modalView.onDismiss = nil;
    }
    
    self.modalView = nil;
    
    if ([self.modalChain count] > 0) {
        MyUIModalView * previousModalView = [self.modalChain objectAtIndex:[self.modalChain count]-1];
        
        [_window.rootViewController.view addSubview:previousModalView];

        [_window.rootViewController.view bringSubviewToFront:busyView];

        [_window.rootViewController.view endEditing:TRUE];
        
        if (self.modalView.onResume) {
            self.modalView.onResume();
        }
        
        self.modalView = previousModalView;
        
        [self.modalChain removeObjectAtIndex:[self.modalChain count]-1];
    }
}

-(void)showModal:(UIView*)contentView isClosable:(BOOL)_isClosable {
    [self showModal:contentView isClosable:_isClosable onDismiss:nil onResume:nil];
}

-(void)showModal:(UIView*)contentView isClosable:(BOOL)_isClosable onDismiss:(void (^)())onDismiss onResume:(void (^)())onResume {
    
    @try {        
        //Cannot re-display a modal which is already in the modalChain
        for (MyUIModalView * chainModal in self.modalChain) {
            if (([contentView superview] && [contentView superview] == chainModal.modalContentView) || chainModal.modalContentView == contentView) {
                return;
            }
        }
        
        //This modal is already being displayed in another view
        if ([contentView superview]) {
            return;
        }
        
        if (modalView) {
            [modalView removeFromSuperview];

            if (modalView.isClosable) {
                if (self.modalView.onDismiss) {
                    self.modalView.onDismiss();
                    self.modalView.onDismiss = nil;
                }
            } else {
                [self.modalChain addObject:modalView];
            }
            
            self.modalView = nil;
        }
        
        [[NSBundle mainBundle] loadNibNamed:@"ModalView" owner:self options:nil];
        
        [modalView.modalContentView addSubview:contentView];
        
        modalView.isClosable = _isClosable;
        
        modalView.frame = _window.frame;
        
        self.modalView.onDismiss = onDismiss;
        self.modalView.onResume = onResume;
        
        if (onResume) {
            onResume();
        }
        
        contentView.frame = CGRectMake(0, 0, modalView.modalContentView.frame.size.width, modalView.modalContentView.frame.size.height);
        
        [_window.rootViewController.view addSubview:modalView];
        
        [_window.rootViewController.view bringSubviewToFront:busyView];
        
        [_window.rootViewController.view endEditing:TRUE];
     } @catch (NSException * e) {
         [UncaughtExceptionHandler logException:e];
     }
    
    @try {
        CATransition *animation = [CATransition animation]; 
        [animation setDuration:ANIMATION_DURATION];
        [animation setType:kCATransitionFade];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        [[_window.rootViewController.view layer] addAnimation:animation forKey:@"ShowModal"];
    } @catch (NSException * e) {
        DLog(@"Animation Exception %@", e);
    }
}

-(void)didFailBackupWallet:(Wallet*)wallet {
    //Don't know a safe way to recover
    //Just clear everything and restart
    
    [self networkActivityStop];
    
    [self.wallet cancelTxSigning];
    
    [_transactionsViewController reload];
    [_receiveViewController reload];
    [_sendViewController reload];
    
    [self.wallet loadGuid:[self guid] sharedKey:[self sharedKey] password:[self password]];
    
    self.wallet.delegate = app;
}

-(void)didBackupWallet:(Wallet*)wallet {
    [_transactionsViewController reload];
    [_receiveViewController reload];
    [_sendViewController reload];
}

-(void)setAccountData:(NSString*)guid sharedKey:(NSString*)sharedKey password:(NSString*)password {

    if ([guid length] != 36) {
        [app standardNotify:@"Invalid GUID"];
        return;
    }
    
    if ([sharedKey length] != 36) {
        [app standardNotify:@"Invalid Shared Key"];
        return;
    }
    
    if ([password length] < 10) {
        [app standardNotify:@"Password should be 10 characters in length or more"];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:guid forKey:@"guid"];
    [[NSUserDefaults standardUserDefaults] setObject:sharedKey forKey:@"sharedKey"];
    [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];

    [app closeModal];
}

-(BOOL)isZBarSupported {
    NSUInteger platformType = [[UIDevice currentDevice] platformType];
    
    if (platformType ==  UIDeviceiPhoneSimulator || platformType ==  UIDeviceiPhoneSimulatoriPhone  || platformType ==  UIDeviceiPhoneSimulatoriPhone || platformType ==  UIDevice1GiPhone || platformType ==  UIDevice3GiPhone || platformType ==  UIDevice1GiPod || platformType ==  UIDevice2GiPod || ![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        return FALSE;
    }
    
    return TRUE;
}

-(IBAction)manualPairClicked:(id)sender {
    
    NSString * guid = manualIdentifier.text;
    NSString * password = manualPassword.text;
    
    if ([guid length] != 36) {
        [app standardNotify:@"Please enter your 36 character wallet identifier correctly. It can be found in the welcome email on startup." title:@"Invalid Identifier" delegate:nil];
        return;
    }
    
    
    [self.wallet loadGuid:guid password:password];
    
    self.wallet.delegate = app;
    
    [app closeModal];
}


-(IBAction)scanAccountQRCodeclicked:(id)sender {
    
    if ([self isZBarSupported]) {
        PairingCodeParser * pairingCodeParser = [[PairingCodeParser alloc] init];
        
        [pairingCodeParser scanAndParse:^(NSDictionary*code) {
            DLog(@"scanAndParse success");
            
            [app forgetWallet];
            
            //If the user has no PIN set force them to create one now
            if (![app isPINSet]) {
                [app showPinModal];
            
                [app standardNotify:[NSString stringWithFormat:@"Before accessing your wallet, please choose a pin number to use to unlock your wallet. It's important you remember this pin as it cannot be reset or changed without first unlocking the app."] title:@"Wallet Paired Successfully." delegate:nil];
            }
            
            [self.wallet loadGuid:[code objectForKey:@"guid"] sharedKey:[code objectForKey:@"sharedKey"] password:[code objectForKey:@"password"]];
            
            self.wallet.delegate = self;
            
        } error:^(NSString*error) {
            [app standardNotify:error];
    
        }];
    } else {
        [self showModal:manualView isClosable:TRUE onDismiss:^() {
            manualPassword.text = nil;
        } onResume:nil];
    }
}

-(void)askForPrivateKey:(NSString*)address success:(void(^)(id))_success error:(void(^)(id))_error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Scan Watch Only Address?"
                                                    message:[NSString stringWithFormat:@"Wallet address %@ has funds available to spend. However the private key needs to be scanned from a paper wallet or QR Code. Would you like to scan the private key now?", address]
                                                   delegate:nil
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    
    alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            _error(@"User Declined");
        } else {
            PrivateKeyReader * reader = [[PrivateKeyReader alloc] init];
            
            [reader readPrivateKey:_success error:_error];
        }
    };
    
    [alert show];
}

-(void)logout {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"password"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self.wallet cancelTxSigning];

    [self.wallet clearLocalStorage];

    self.wallet.password = nil;
    
    [self.wallet loadJS];

    self.latestResponse = nil;
    
    _transactionsViewController.data = nil;
    [_transactionsViewController reload];
    [_receiveViewController reload];
    [_sendViewController reload];
    [_accountViewController emptyWebView];
    
    [self transitionToIndex:0];
}

-(void)forgetWallet {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"guid"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sharedKey"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"password"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];   
    
    [self.wallet cancelTxSigning];

    [self.wallet clearLocalStorage];
    
    self.wallet.password = nil;

    [self.wallet loadJS];

    self.latestResponse = nil;
    [_transactionsViewController setData:nil];
    
    [self transitionToIndex:0];
}

#pragma mark - Show Screens

-(void)showAccountSettings {
    if (!_accountViewController) {
        _accountViewController = [[AccountViewController alloc] initWithNibName:@"AccountViewController" bundle:[NSBundle mainBundle]];
    }
    
    [_tabViewController setActiveViewController:_accountViewController];
}

-(void)showMerchant {
    
    if (!_merchantViewController) {
        _merchantViewController = [[MerchantViewController alloc] initWithNibName:@"MerchantMap" bundle:[NSBundle mainBundle]];
    }
    
    [_tabViewController setActiveViewController:_merchantViewController  animated:TRUE index:3];
}

-(void)showSendCoins {
    
    if (!_sendViewController) {
        _sendViewController = [[SendViewController alloc] initWithNibName:@"SendCoins" bundle:[NSBundle mainBundle]];
    }
    
    [_tabViewController setActiveViewController:_sendViewController  animated:TRUE index:2];
}

-(void)clearPin {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"pin"];
}

-(BOOL)isPINSet {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"pin"] != nil;
}

- (void)showPinModal
{
    // if pin exists - verify
    if ([self isPINSet])
    {
        self.pinEntryViewController = [PEPinEntryController pinVerifyController];
    }
    // no pin - create
    else
    {
        self.pinEntryViewController = [PEPinEntryController pinCreateController];
    }
    
    self.pinEntryViewController.navigationBarHidden = YES;
    self.pinEntryViewController.pinDelegate = self;
    
    [_window.rootViewController presentViewController:self.pinEntryViewController animated:NO completion:nil];
//    [_window bringSubviewToFront:self.pinEntryViewController.view];
}

// Modal menu
-(void)showWelcome {
    [app showModal:welcomeView isClosable:[self guid] != nil onDismiss:nil onResume:^() {
        
        [welcomeButton3 setHidden:![self isPINSet]];
        [welcomeButton3 setTitle:@"Change PIN" forState:UIControlStateNormal];
        
        // User is logged in
        if ([self password]) {
            welcomeLabel.text = @"Options";
            welcomeInstructionsLabel.text = @"Open Account Settings, Logout or change your pin below.";
            [welcomeButton1 setTitle:@"Account Settings" forState:UIControlStateNormal];
            [welcomeButton1 setBackgroundImage:[UIImage imageNamed:@"button_blue.png"] forState:UIControlStateNormal];
            [welcomeButton2 setTitle:@"Logout" forState:UIControlStateNormal];
        }
        // Wallet paired, but no password
        else if ([self guid] || [self sharedKey]) {
            welcomeLabel.text = @"Welcome Back";
            welcomeInstructionsLabel.text = @"";
            [welcomeButton1 setTitle:@"Account Settings" forState:UIControlStateNormal];
            [welcomeButton1 setBackgroundImage:[UIImage imageNamed:@"button_blue.png"] forState:UIControlStateNormal];
            [welcomeButton2 setTitle:@"Forget Details" forState:UIControlStateNormal];
        }
        // User is completed logged out
        else {
            welcomeLabel.text = @"Welcome to Blockchain Wallet";
            welcomeInstructionsLabel.text = @"If you already have a Blockchain Wallet, choose Pair Device; otherwise, choose Create Wallet.    It's Free! No email required.";
            
            [welcomeButton1 setTitle:@"Create Wallet" forState:UIControlStateNormal];
            [welcomeButton1 setBackgroundImage:[UIImage imageNamed:@"button_green.png"] forState:UIControlStateNormal];
            [welcomeButton2 setTitle:@"Pair Device" forState:UIControlStateNormal];
        }
    }];
}

#pragma mark - Actions

-(IBAction)powerClicked:(id)sender {
    [self showWelcome];
}


//Change PIN
-(IBAction)welcomeButton3Clicked:(id)sender {
    PEPinEntryController *c = [PEPinEntryController pinChangeController];
    c.pinDelegate = self;
    c.navigationBarHidden = YES;
    
    PEViewController *peViewController = (PEViewController *)[[c viewControllers] objectAtIndex:0];
    peViewController.cancelButton.hidden = NO;
    
    [self.tabViewController presentViewController:c animated:YES completion:nil];
}

-(IBAction)welcomeButton1Clicked:(id)sender {
    //Wallet is already paired
    if ([self guid] || [self sharedKey])  {
        [app closeModal];
        
        [app showAccountSettings];
    } else {
    //No Wallet show New Wallet creation
        [app showModal:newAccountView isClosable:TRUE];
    }
}

-(IBAction)welcomeButton2Clicked:(id)sender {
    // Logout
    if ([self password]) {
        [self logout];
        
        [app closeModal];
        
        [self walletFailedToDecrypt:wallet]; // misleading method name
    }
    // Forget wallet
    else if ([self guid] || [self sharedKey]) {
        
        // confirm forget wallet
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning!!!"
                                                        message:@"This will erase all wallet data on this device. Please confirm you have your wallet information saved elsewhere otherwise any bitcoins in this wallet will be inaccessible!!"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Forget Wallet", nil];
        alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
            // Forget Wallet Cancelled
            if (buttonIndex == 0) {
            }
            // Forget Wallet Confirmed
            else if (buttonIndex == 1) {
                DLog(@"forgetting wallet");
                [app closeModal];
                [self forgetWallet];
                [app showWelcome];
            }
        };
        
        [alert show];

    }
    // Do pair
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"How would you like to pair?"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Manually"
                                              otherButtonTitles:@"Automatically", nil];

        alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
            // Manually
            if (buttonIndex == 0) {
                [app showModal:manualView isClosable:TRUE];
            }
            // QR
            else if (buttonIndex == 1) {
                [app showModal:pairingInstructionsView isClosable:TRUE];
            }
        };

        
        [alert show];
    }
}


-(IBAction)forgetWalletClicked:(id)sender {
    [self welcomeButton2Clicked:sender];
}


-(IBAction)receiveCoinClicked:(UIButton *)sender {
    if (!_receiveViewController) {
        _receiveViewController = [[ReceiveCoinsViewController alloc] initWithNibName:@"ReceiveCoins" bundle:[NSBundle mainBundle]];
    }
        
    [_tabViewController setActiveViewController:_receiveViewController animated:TRUE index:1];
}

-(IBAction)transactionsClicked:(UIButton *)sender {
    [_tabViewController setActiveViewController:_transactionsViewController animated:TRUE index:0];
}

-(IBAction)sendCoinsClicked:(UIButton *)sender {
    [self showSendCoins];
}

-(IBAction)merchantClicked:(UIButton *)sender {
    [self showMerchant];
}

-(IBAction)accountSettingsClicked:(UIButton *)sender {
    [self showAccountSettings];
}

-(IBAction)mainPasswordClicked:(id)sender {
    
    NSString * password = mainPasswordTextField.text;
    
    password = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([mainPasswordTextField.text length] < 10) {
        [app standardNotify:@"Passowrd must be 10 or more characters in length"];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString * guid = [[NSUserDefaults standardUserDefaults] objectForKey:@"guid"];
    NSString * sharedKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"sharedKey"];
    
    if (guid && sharedKey && password) {
        
        [self.wallet loadGuid:guid sharedKey:sharedKey password:password];
        
        self.wallet.delegate = self;
    }
    
    mainPasswordTextField.text = nil;
    
    [app closeModal];
}

-(IBAction)refreshClicked:(id)sender {
    if (![self guid] || ![self sharedKey]) {
        [app showWelcome];
        return;
    }
    
    //If displaying the merchant view controller refresh the map instead
    if (_tabViewController.activeViewController == _merchantViewController) {
        [_merchantViewController refresh];
        
    //Otherwise just fetch the transaction history again
    } else {
        [self.wallet getWalletAndHistory];
    }

}

#pragma mark - Accessors

-(NSString*)password {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
}

-(NSString*)guid {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"guid"];
}

-(NSString*)sharedKey {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"sharedKey"];
}

#pragma mark - Pin Entry Delegates

- (BOOL)pinEntryController:(PEPinEntryController *)c shouldAcceptPin:(NSUInteger)pin
{
    NSNumber *pinObj = [[NSUserDefaults standardUserDefaults] objectForKey:@"pin"];
    
	if(pinObj && pin == [pinObj intValue])
    {
		if(c.verifyOnly == YES)
        {
			[_tabViewController dismissViewControllerAnimated:YES completion:^{
            }];
		}
        
		return YES;
	}
    else
    {
		return NO;
	}
}

- (void)pinEntryController:(PEPinEntryController *)c changedPin:(NSUInteger)pin
{
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInt:pin] forKey:@"pin"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    DLog(@"Saved new pin");
    
	// Update your info to new pin code
	[_tabViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)pinEntryControllerDidCancel:(PEPinEntryController *)c
{
	DLog(@"Pin change cancelled!");
	[_tabViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Format helpers

-(NSString*)formatMoney:(uint64_t)value localCurrency:(BOOL)fsymbolLocal {
    if (fsymbolLocal && latestResponse.symbol_local.conversion) {
        @try {
            BOOL negative = false;
            
            NSDecimalNumber * number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:value] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithDouble:(double)latestResponse.symbol_local.conversion]];
            
            if ([number compare:[NSNumber numberWithInt:0]] < 0) {
                number = [number decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]];
                negative = TRUE;
            }
            
            if (negative)
                return [@"-" stringByAppendingString:[latestResponse.symbol_local.symbol stringByAppendingString:[self.localCurrencyFormatter stringFromNumber:number]]];
            else
                return [latestResponse.symbol_local.symbol stringByAppendingString:[self.localCurrencyFormatter stringFromNumber:number]];
            
        } @catch (NSException * e) {
            DLog(@"%@", e);
        }
    } else if (latestResponse.symbol_btc) {
        NSDecimalNumber * number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:value] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:latestResponse.symbol_btc.conversion]];
        
        NSString * string = [self.btcFormatter stringFromNumber:number];
        
        return [string stringByAppendingFormat:@" %@", latestResponse.symbol_btc.symbol];
    }
    
    NSDecimalNumber * number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:value] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithDouble:SATOSHI]];
    
    NSString * string = [self.btcFormatter stringFromNumber:number];
    
    return [string stringByAppendingString:@" BTC"];
}

-(NSString*)formatMoney:(uint64_t)value {
    return [self formatMoney:value localCurrency:symbolLocal];
}

@end
