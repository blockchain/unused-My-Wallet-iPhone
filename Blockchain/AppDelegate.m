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
#import "NSData+Hex.h"
#import <AVFoundation/AVFoundation.h>

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
    
    [self showWelcome:FALSE];

    //If either of this is nil we are not properyl paired
    if ([self guid] && [self sharedKey]) {
        //We are properly paired here
        //If the PIN is set show the entry modal
        if ([self isPINSet]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self showPinModal];
            });
        } else {
            //No PIN set we need to ask for the main password
            [self showMainPasswordModalOrWelcomeMenu];
        }
        
        
        NSString * guid = [self guid];
        NSString * sharedKey = [self sharedKey];
        
        if (guid && sharedKey) {
            [self.wallet loadGuid:guid sharedKey:sharedKey];
        }
        
        /* Old Password & PIN */
        NSString * password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
        NSString * pin = [[NSUserDefaults standardUserDefaults] objectForKey:@"pin"];
        
        if (password && pin) {
            self.wallet.password = password;
            
            [self savePIN:pin];
            
            //Remove now save
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"password"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"pin"];
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

-(void)didWalletDecryptStart {
    [self networkActivityStart];
}

-(void)didWalletDecryptFinish {
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
	[self standardNotify:message title:BC_STRING_ERROR delegate:nil];
}

- (void)standardNotify:(NSString*)message delegate:(id)fdelegate
{
	[self standardNotify:message title:BC_STRING_ERROR delegate:fdelegate];
}

- (void)standardNotify:(NSString*)message title:(NSString*)title delegate:(id)fdelegate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message  delegate:fdelegate cancelButtonTitle:BC_STRING_OK otherButtonTitles: nil];
            [alert show];
        }
    });
}

-(void)walletDidLoad {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self endBackgroundUpdateTask];
    });
}

-(void)walletFailedToLoad {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //If the PIN View controller is visible don't dislay the error yet
        if ([_tabViewController presentedViewController] == self.pinEntryViewController) {
            return;
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BC_STRING_FAILED_TO_LOAD_WALLET_TITLE
                                                        message:[NSString stringWithFormat:BC_STRING_FAILED_TO_LOAD_WALLET_DETAIL]
                                                       delegate:nil
                                              cancelButtonTitle:BC_STRING_FORGET_WALLET
                                              otherButtonTitles:BC_STRING_CLOSE_APP, nil];
        
        alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) {
                UIApplication *app = [UIApplication sharedApplication];
                
                [app performSelector:@selector(suspend)];
            } else {
                [self forgetWalletAlert:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    // Forget Wallet Cancelled
                    if (buttonIndex == 0) {
                        [self walletFailedToLoad];
                    }
                    // Forget Wallet Confirmed
                    else if (buttonIndex == 1) {
                        [self forgetWallet];
                        [app showWelcome];
                    }
                }];
            }
        };
        
        [alert show];
    });
}

-(void)walletDidDecrypt {
    DLog(@"walletDidDecrypt");
    
    [self transitionToIndex:0];

    [self setAccountData:wallet.guid sharedKey:wallet.sharedKey];
    
    [_transactionsViewController reload];
    [_receiveViewController reload];
    [_sendViewController reload];
    
    [app closeAllModals];
    
    //Becuase we are not storing the password on the device. We record the first few letters of the hashed password.
    //With the hash prefix we can then figure out if the password changed
    NSString * passwordPartHash = [[NSUserDefaults standardUserDefaults] objectForKey:@"passwordPartHash"];
    if (![[[app.wallet.password SHA256] substringToIndex:MIN([app.wallet.password length], 5)] isEqualToString:passwordPartHash]) {
        [self clearPin];
    }
    
    if (![app isPINSet]) {
        [app showPinModal];
    }
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

-(void)walletFailedToDecrypt {
    [self showMainPasswordModalOrWelcomeMenu];
}

-(void)showMainPasswordModalOrWelcomeMenu {
    
    if ([self guid]) {        
        [self showModal:mainPasswordView isClosable:FALSE];
        
        [mainPasswordTextField becomeFirstResponder];
    } else {
        //Called when bad password is entered when maually pairing
        [app showWelcome];
    }
}

- (void) beginBackgroundUpdateTask
{
    self.backgroundUpdateTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundUpdateTask];
    }];
}

- (void) endBackgroundUpdateTask
{
    [[UIApplication sharedApplication] endBackgroundTask: self.backgroundUpdateTask];
    self.backgroundUpdateTask = UIBackgroundTaskInvalid;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [app closeAllModals];

    [self closePINModal:NO]; //Close PIN Modal incase we are setting it

    if ([wallet isInitialized]) {
        [self beginBackgroundUpdateTask];

        [self logout];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    if ([self isPINSet]) {
        [self showPinModal];
    }
    
    if (![wallet isInitialized]) {
        [app showWelcome:FALSE];
        
        if ([self guid] && [self sharedKey]) {
            [self showModal:mainPasswordView isClosable:FALSE];
        }
    }
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
    
    secondPasswordDescriptionLabel.text = BC_STRING_PRIVATE_KEY_ENCRYPTED_DESCRIPTION;

    [app showModal:secondPasswordView isClosable:TRUE onDismiss:^() {
        NSString * password = secondPasswordTextField.text;
        
        if ([password length] == 0) {
            if (error) error(BC_STRING_NO_PASSWORD_ENTERED);
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
        [app standardNotify:BC_STRING_SECOND_PASSWORD_INCORRECT];
        secondPasswordTextField.text = nil;
    }
}

-(void)getSecondPassword:(void (^)(NSString *))success error:(void (^)(NSString *))error {
    
    secondPasswordDescriptionLabel.text = BC_STRING_ACTION_REQUIRES_SECOND_PASSWORD;
    
    validateSecondPassword = TRUE;
    
    [app showModal:secondPasswordView isClosable:TRUE onDismiss:^() {
        NSString * password = secondPasswordTextField.text;
                    
        if ([password length] == 0) {
            if (error) error(BC_STRING_NO_PASSWORD_ENTERED);
        } else if(![wallet validateSecondPassword:password]) {
            if (error) error(BC_STRING_SECOND_PASSWORD_INCORRECT);
        } else {
            if (success) success(password);
        }
        
        secondPasswordTextField.text = nil;
    } onResume:nil];
    
    [secondPasswordTextField becomeFirstResponder];
}


-(void)closeAllModals {
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
    
    for (MyUIModalView * modalChainView in self.modalChain) {
        
        for (UIView * subView in [modalChainView.modalContentView subviews]) {
            [subView removeFromSuperview];
        }
        
        [modalChainView.modalContentView removeFromSuperview];
        
        if (modalChainView.onDismiss) {
            modalChainView.onDismiss();
        }
    }
    
    [self.modalChain removeAllObjects];
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

    //This modal is already being displayed in another view
    if ([contentView superview]) {
        if (self.modalView.modalContentView == [contentView superview]) {
            if (self.modalView.onResume)
                self.modalView.onResume();
        }
        
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
    
    if ([contentView isKindOfClass:[ZBarReaderView class]]) {
        self.readerViewTapSubView = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                                             contentView.frame.size.width,
                                                                             contentView.frame.size.height)];
        UITapGestureRecognizer* tapScanner = [[UITapGestureRecognizer alloc] initWithTarget:app action:@selector(focusAtPoint:)];
        [self.readerViewTapSubView addGestureRecognizer:tapScanner];
        [contentView addSubview:self.readerViewTapSubView];
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

- (void)focusAtPoint:(id) sender {
    
    CGPoint touchPoint = [(UITapGestureRecognizer*)sender locationInView:self.readerViewTapSubView];
    double focus_x = touchPoint.x/self.readerViewTapSubView.frame.size.width;
    double focus_y = (touchPoint.y+66)/self.readerViewTapSubView.frame.size.height;
    NSError *error;
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices){
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if ([device position] == AVCaptureDevicePositionBack) {
                CGPoint point = CGPointMake(focus_y, 1-focus_x);
                if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] && [device lockForConfiguration:&error]){
                    [device setFocusPointOfInterest:point];
                    CGRect rect = CGRectMake(touchPoint.x-30, touchPoint.y-30, 60, 60);
                    UIView *focusRect = [[UIView alloc] initWithFrame:rect];
                    focusRect.layer.borderColor = [UIColor whiteColor].CGColor;
                    focusRect.layer.borderWidth = 2;
                    focusRect.tag = 99;
                    [self.readerViewTapSubView addSubview:focusRect];
                    [NSTimer scheduledTimerWithTimeInterval: 1
                                                     target: self
                                                   selector: @selector(dismissFocusRect)
                                                   userInfo: nil
                                                    repeats: NO];
                    [device setFocusMode:AVCaptureFocusModeAutoFocus];
                    [device unlockForConfiguration];
                }
            }
        }
    }
}

- (void) dismissFocusRect {
    for (UIView *subView in self.readerViewTapSubView.subviews)
    {
        if (subView.tag == 99)
        {
            [subView removeFromSuperview];
        }
    }
}

-(void)didFailBackupWallet {

#pragma mark why is this needed?
    [self networkActivityStop];
    
    //Cancel any tx signing just incase
    [self.wallet cancelTxSigning];
    
    //Refresh the wallet and history
    [self.wallet getWalletAndHistory];
}

-(void)didBackupWallet {
    [_transactionsViewController reload];
    [_receiveViewController reload];
    [_sendViewController reload];
}

-(void)setAccountData:(NSString*)guid sharedKey:(NSString*)sharedKey {

    if ([guid length] != 36) {
        [app standardNotify:BC_STRING_INVALID_GUID];
        return;
    }
    
    if ([sharedKey length] != 36) {
        [app standardNotify:BC_STRING_INVALID_SHARED_KEY];
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:guid forKey:@"guid"];
    [[NSUserDefaults standardUserDefaults] setObject:sharedKey forKey:@"sharedKey"];
    
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
        [app standardNotify:BC_STRING_ENTER_YOUR_CHARACTER_WALLET_IDENTIFIER title:BC_STRING_INVALID_IDENTIFIER delegate:nil];
        return;
    }
    
    [self.wallet loadGuid:guid];
    
    self.wallet.password = password;
    
    self.wallet.delegate = self;
    
    [app closeModal];
}


-(IBAction)scanAccountQRCodeclicked:(id)sender {
    
    if ([self isZBarSupported]) {
        PairingCodeParser * pairingCodeParser = [[PairingCodeParser alloc] init];
        
        [pairingCodeParser scanAndParse:^(NSDictionary*code) {
            DLog(@"scanAndParse success");
            
            [app forgetWallet];
            
            [app clearPin];
            
            [app standardNotify:[NSString stringWithFormat:BC_STRING_WALLET_PAIRED_SUCCESSFULLY_DETAIL] title:BC_STRING_WALLET_PAIRED_SUCCESSFULLY_TITLE delegate:nil];
            
            [self.wallet loadGuid:[code objectForKey:@"guid"] sharedKey:[code objectForKey:@"sharedKey"]];
            
            self.wallet.password = [code objectForKey:@"password"];
            
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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BC_STRING_ASK_FOR_PRIVATE_KEY_TITLE
                                            message:[NSString stringWithFormat:BC_STRING_ASK_FOR_PRIVATE_KEY_DETAIL, address]
                                           delegate:nil
                                  cancelButtonTitle:BC_STRING_NO
                                  otherButtonTitles:BC_STRING_YES, nil];

    alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            _error(BC_STRING_USER_DECLINED);
        } else {
            PrivateKeyReader * reader = [[PrivateKeyReader alloc] init];
            
            [reader readPrivateKey:_success error:_error];
        }
    };
    
    [alert show];
}

-(void)logout {
    [self.wallet cancelTxSigning];
    
    [self.wallet loadBlankWallet];

    self.latestResponse = nil;
    
    _transactionsViewController.data = nil;
    
    [_transactionsViewController reload];
    [_receiveViewController reload];
    [_sendViewController reload];
    [_accountViewController emptyWebView];
    
    [self transitionToIndex:0];
}

-(void)forgetWallet {
    
    [self clearPin];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"guid"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sharedKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];   
    
    [self.wallet cancelTxSigning];

    [self.wallet clearLocalStorage];
    
    [self.wallet loadBlankWallet];

    self.latestResponse = nil;
    
    [_transactionsViewController setData:nil];
    
    [_transactionsViewController reload];
    [_receiveViewController reload];
    [_sendViewController reload];
    [_accountViewController emptyWebView];
    
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
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"encryptedPINPassword"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"passwordPartHash"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"pinKey"];
}

-(BOOL)isPINSet {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"pinKey"] != nil && [[NSUserDefaults standardUserDefaults] objectForKey:@"encryptedPINPassword"] != nil;
}

-(void)closePINModal:(BOOL)animated
{
    [_tabViewController dismissViewControllerAnimated:animated completion:^{ }];
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
    
    [self.pinEntryViewController setActivityIndicatorAnimated:FALSE];
}

// Modal menu
-(void)showWelcome {
    [self showWelcome:[self guid] && [self sharedKey]];
}

-(void)showWelcome:(BOOL)isClosable {
    [app showModal:welcomeView isClosable:isClosable onDismiss:nil onResume:^() {
        
        [welcomeButton3 setHidden:![self isPINSet]];
        [welcomeButton3 setTitle:BC_STRING_CHANGE_PIN forState:UIControlStateNormal];
        
        // User is logged in
        if ([self.wallet isInitialized]) {
            welcomeLabel.text = BC_STRING_OPTIONS;
            welcomeInstructionsLabel.text = BC_STRING_OPEN_ACCOUNT_SETTINGS;
            [welcomeButton1 setTitle:BC_STRING_ACCOUNT_SETTINGS forState:UIControlStateNormal];
            [welcomeButton1 setBackgroundImage:[UIImage imageNamed:@"button_blue.png"] forState:UIControlStateNormal];
            [welcomeButton2 setTitle:BC_STRING_LOGOUT forState:UIControlStateNormal];
        }
        // Wallet paired, but no password
        else if ([self guid] && [self sharedKey]) {
            welcomeLabel.text = BC_STRING_WELCOME_BACK;
            welcomeInstructionsLabel.text = @"";
            [welcomeButton1 setTitle:BC_STRING_ACCOUNT_SETTINGS forState:UIControlStateNormal];
            [welcomeButton1 setBackgroundImage:[UIImage imageNamed:@"button_blue.png"] forState:UIControlStateNormal];
            [welcomeButton2 setTitle:BC_STRING_FORGET_DETAILS forState:UIControlStateNormal];
        }
        // User is completed logged out
        else {
            welcomeLabel.text = BC_STRING_WELCOME_TO_BLOCKCHAIN_WALLET;
            welcomeInstructionsLabel.text = BC_STRING_WELCOME_INSTRUCTIONS;
            
            [welcomeButton1 setTitle:BC_STRING_CREATE_WALLET forState:UIControlStateNormal];
            [welcomeButton1 setBackgroundImage:[UIImage imageNamed:@"button_green.png"] forState:UIControlStateNormal];
            [welcomeButton2 setTitle:BC_STRING_PAIR_DEVICE forState:UIControlStateNormal];
        }
    }];
}

#pragma mark - Actions

-(IBAction)powerClicked:(id)sender {
    [self showWelcome];
}


-(void)changePIN {
    PEPinEntryController *c = [PEPinEntryController pinChangeController];
    c.pinDelegate = self;
    c.navigationBarHidden = YES;
    
    PEViewController *peViewController = (PEViewController *)[[c viewControllers] objectAtIndex:0];
    peViewController.cancelButton.hidden = NO;
    
    [self.tabViewController presentViewController:c animated:YES completion:nil];
}

//Change PIN
-(IBAction)welcomeButton3Clicked:(id)sender {
    [self changePIN];
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

-(void)forgetWalletAlert:(void (^)(UIAlertView *alertView, NSInteger buttonIndex))tapBlock {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BC_STRING_WARNING
                                                    message:BC_STRING_FORGET_WALLET_DETAILS
                                                   delegate:self
                                          cancelButtonTitle:BC_STRING_CANCEL
                                          otherButtonTitles:BC_STRING_FORGET_WALLET, nil];
    alert.tapBlock = tapBlock;
    
    [alert show];

}

-(IBAction)welcomeButton2Clicked:(id)sender {
    // Logout
    if (self.wallet.password) {
        [self clearPin];

        [self logout];
        
        [app closeModal];
        
        [self showMainPasswordModalOrWelcomeMenu]; // misleading method name
    }
    // Forget wallet
    else if ([self guid] && [self sharedKey]) {
        
        // confirm forget wallet
        
        [self forgetWalletAlert:^(UIAlertView *alertView, NSInteger buttonIndex) {
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
        }];

    }
    // Do pair
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BC_STRING_HOW_WOULD_YOU_LIKE_TO_PAIR
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:BC_STRING_MANUALLY
                                              otherButtonTitles:BC_STRING_AUTOMATICALLY, nil];

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

    NSString * password = [mainPasswordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([mainPasswordTextField.text length] < 10) {
        [app standardNotify:BC_STRING_PASSWORD_MUST_10_CHARACTERS_OR_LONGER];
        return;
    }
    
    NSString * guid = [[NSUserDefaults standardUserDefaults] objectForKey:@"guid"];
    NSString * sharedKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"sharedKey"];
    
    if (guid && sharedKey && password) {
        
        [self.wallet loadGuid:guid sharedKey:sharedKey];

        self.wallet.password = password;
        
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

-(NSString*)guid {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"guid"];
}

-(NSString*)sharedKey {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"sharedKey"];
}

#pragma mark - Pin Entry Delegates

- (void)pinEntryController:(PEPinEntryController *)c shouldAcceptPin:(NSUInteger)_pin callback:(void(^)(BOOL))callback
{
    if(c.verifyOnly != YES)
    {
        callback(YES);
        return;
    };
        
    self.lastEnteredPIN = _pin;

    if (!app.wallet) {
        [self askIfUserWantsToResetPIN];
        return;
    }
    
    NSString * pinKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"pinKey"];
    NSString * pin = [NSString stringWithFormat:@"%d", _pin];
    
    [self.pinEntryViewController setActivityIndicatorAnimated:TRUE];

    [app.wallet apiGetPINValue:pinKey pin:pin];
    
    self.pinViewControllerCallback = callback;
}

-(void)askIfUserWantsToResetPIN {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BC_STRING_PIN_VALIDATION_ERROR
                                                    message:BC_STRING_PIN_VALIDATION_ERROR_DETAIL
                                                   delegate:self
                                          cancelButtonTitle:BC_STRING_ENTER_PASSWORD
                                          otherButtonTitles:RETRY_VALIDATION, nil];
    
    alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            [self closePINModal:YES];
            
            [self showMainPasswordModalOrWelcomeMenu];
        } else if (buttonIndex == 1) {
            [self pinEntryController:self.pinEntryViewController shouldAcceptPin:self.lastEnteredPIN callback:self.pinViewControllerCallback];
        }
    };
    
    [alert show];

}


-(void)didFailGetPin:(NSString*)value {
    [self.pinEntryViewController setActivityIndicatorAnimated:FALSE];
    
    [self askIfUserWantsToResetPIN];
}

-(void)didGetPinSuccess:(NSDictionary*)dictionary {
    [self.pinEntryViewController setActivityIndicatorAnimated:FALSE];
    
    NSNumber * code = [dictionary objectForKey:@"code"]; //This is a status code from the server
    NSString * error = [dictionary objectForKey:@"error"]; //This is an error string from the server or nil
    NSString * success = [dictionary objectForKey:@"success"]; //The PIN decryption value from the server
    NSString * encryptedPINPassword = [[NSUserDefaults standardUserDefaults] objectForKey:@"encryptedPINPassword"];
    
    BOOL pinSuccess = FALSE;
    if (code == nil) {
        [app standardNotify:[NSString stringWithFormat:BC_STRING_SERVER_RETURNED_NULL_STATUS_CODE]];
    } else if ([code intValue] == PIN_API_STATUS_CODE_DELETED) {
        [app standardNotify:BC_STRING_PIN_VALIDATION_CANNOT_BE_COMPLETED];
        
        [self clearPin];
        
        [self showMainPasswordModalOrWelcomeMenu];
        
        [self closePINModal:YES];
    } else if ([code integerValue] == PIN_API_STATUS_PIN_INCORRECT) {
        
        if (error == nil) {
            error = @"PIN Code Incorrect. Unknown Error Message.";
        }
        
        [app standardNotify:error];
    } else if ([code intValue] == PIN_API_STATUS_OK) {
        
        if ([success length] == 0) {
            [app standardNotify:BC_STRING_PIN_RESPONSE_OBJECT_SUCCESS_LENGTH_0];
            [self askIfUserWantsToResetPIN];
            return;
        }
        
        NSString * decrypted = [app.wallet decrypt:encryptedPINPassword password:success pbkdf2_iterations:PIN_PBKDF2_ITERATIONS];
        
        if ([decrypted length] == 0) {
            [app standardNotify:BC_STRING_DECRYPTED_PIN_PASSWORD_LENGTH_0];
            [self askIfUserWantsToResetPIN];
            return;
        }
        
        NSString * guid = [self guid];
        NSString * sharedKey = [self sharedKey];
        
        if (guid && sharedKey) {
            [self.wallet loadGuid:guid sharedKey:sharedKey];
        }
        
        app.wallet.password = decrypted;
        
        [self closePINModal:YES];

        pinSuccess = TRUE;
    } else {
        //Unknown error
        [self askIfUserWantsToResetPIN];
    }
    
    if (self.pinViewControllerCallback) {
        self.pinViewControllerCallback(pinSuccess);
        self.pinViewControllerCallback = nil;
    }
}

-(void)didFailPutPin:(NSString*)value {
    [self.pinEntryViewController setActivityIndicatorAnimated:FALSE];

    [app standardNotify:value];
    
    [self closePINModal:YES];
}

-(void)didPutPinSuccess:(NSDictionary*)dictionary {
    [self.pinEntryViewController setActivityIndicatorAnimated:FALSE];

    if (!app.wallet.password) {
        [self didFailPutPin:BC_STRING_CANNOT_SAVE_PIN_CODE_WHILE];
        return;
    }
    
    NSNumber * code = [dictionary objectForKey:@"code"]; //This is a status code from the server
    NSString * error = [dictionary objectForKey:@"error"]; //This is an error string from the server or nil
    NSString * key = [dictionary objectForKey:@"key"]; //This is our pin code lookup key
    NSString * value = [dictionary objectForKey:@"value"]; //This is our encryption string

    if (error != nil) {
        [self didFailPutPin:error];
    } else if (code == nil || [code intValue] != PIN_API_STATUS_OK) {
        [self didFailPutPin:[NSString stringWithFormat:BC_STRING_INVALID_STATUS_CODE_RETURNED, code]];
    } else if ([key length] == 0 || [value length] == 0) {
        [self didFailPutPin:BC_STRING_PIN_RESPONSE_OBJECT_KEY_OR_VALUE_LENGTH_0];
    } else {
        //Encrypt the wallet password with the random value
        NSString * encrypted = [app.wallet encrypt:app.wallet.password password:value pbkdf2_iterations:PIN_PBKDF2_ITERATIONS];

        //Store the encrypted result and discard the value
        value = nil;

        if (!encrypted) {
            [self didFailPutPin:BC_STRING_PIN_ENCRYPTED_STRING_IS_NIL];
            return;
        }
        
        [[NSUserDefaults standardUserDefaults] setValue:encrypted forKey:@"encryptedPINPassword"];
        [[NSUserDefaults standardUserDefaults] setValue:[[app.wallet.password SHA256] substringToIndex:MIN([app.wallet.password length], 5)] forKey:@"passwordPartHash"];
        [[NSUserDefaults standardUserDefaults] setValue:key forKey:@"pinKey"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Update your info to new pin code
        [self closePINModal:YES];
        
        [app standardNotify:BC_STRING_PIN_SAVED_SUCCESSFULLY title:BC_STRING_SUCCESS delegate:nil];
    }
}

- (void)pinEntryController:(PEPinEntryController *)c changedPin:(NSUInteger)_pin
{
    if (![app.wallet isInitialized] || !app.wallet.password) {
        [self didFailPutPin:BC_STRING_CANNOT_SAVE_PIN_CODE_WHILE];
        return;
    }
    
    NSString * pin = [NSString stringWithFormat:@"%d", _pin];
    
    [self.pinEntryViewController setActivityIndicatorAnimated:TRUE];

    [self savePIN:pin];
}

- (void)savePIN:(NSString*)pin {
    uint8_t data[32];
    int err = 0;
    
    //32 Random bytes for key
    err = SecRandomCopyBytes(kSecRandomDefault, 32, data);
    if(err != noErr)
        @throw [NSException exceptionWithName:@"..." reason:@"..." userInfo:nil];
    
    NSString * key = [[[NSData alloc] initWithBytes:data length:32] hexadecimalString];
    
    //32 random bytes for value
    err = SecRandomCopyBytes(kSecRandomDefault, 32, data);
    if(err != noErr)
        @throw [NSException exceptionWithName:@"..." reason:@"..." userInfo:nil];
    
    NSString * value = [[[NSData alloc] initWithBytes:data length:32] hexadecimalString];
    
    [app.wallet pinServerPutKeyOnPinServerServer:key value:value pin:pin];
}

- (void)pinEntryControllerDidCancel:(PEPinEntryController *)c
{
	DLog(@"Pin change cancelled!");
	[self closePINModal:YES];
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
