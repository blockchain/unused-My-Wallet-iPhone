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
#import "UIFadeView.h"
#import "TabViewController.h"
#import "ReceiveCoinsViewController.h"
#import "SendViewController.h"
#import "AccountViewController.h"
#import "TransactionsViewController.h"
#import "WebViewController.h"
#import "NewAccountView.h"
#import "NSString+SHA256.h"
#import "JSONKit.h"
#import "Transaction.h"
#import "Input.h"
#import "Output.h"
#import "UIDevice+Hardware.h"
#import "UncaughtExceptionHandler.h"

AppDelegate * app;

@implementation AppDelegate

@synthesize window = _window;
@synthesize wallet;
@synthesize reachability;
@synthesize modalView;
@synthesize modalContentView;
@synthesize latestResponse;
@synthesize modalDelegate;
@synthesize readerView;

#pragma mark - Lifecycle

-(id)init {
    if (self = [super init]) {
         
        btcFromatter = [[NSNumberFormatter alloc] init];  
    
        [btcFromatter setMaximumSignificantDigits:5];
        [btcFromatter setMaximumFractionDigits:5];
        
        [btcFromatter setNumberStyle:NSNumberFormatterDecimalStyle];

        app = self;
        tasks = 0;
        
    }
    return self;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    wallet.secondPassword  = nil;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self showPinModal];
}

- (void)installUncaughtExceptionHandler
{
	InstallUncaughtExceptionHandler();
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self performSelector:@selector(installUncaughtExceptionHandler) withObject:nil afterDelay:0];
    
    // Override point for customization after application launch.
    _window.backgroundColor = [UIColor whiteColor];
    
    [_window makeKeyAndVisible];
    
    //Netowrk status updates
    self.reachability = [Reachability reachabilityForInternetConnection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(reachabilityChanged:) name:kReachabilityChangedNotification object: nil];
    [reachability startNotifer];
    
    tabViewController = oldTabViewController;
    
    [_window setRootViewController:tabViewController];
    
    if (![self guid] || ![self sharedKey]) {
        [self showWelcome];
        
    } else if (![self password]) {
        
        [self showModal:mainPasswordView];
        
        [mainPasswordTextField becomeFirstResponder];
        
    } else {
        
        NSString * guid = [[NSUserDefaults standardUserDefaults] objectForKey:@"guid"];
        NSString * sharedKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"sharedKey"];
        NSString * password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];

        if (guid && sharedKey && password) {
            self.wallet = [[Wallet alloc] initWithGuid:guid sharedKey:sharedKey password:password];
        }
    }
    
    [tabViewController setActiveViewController:transactionsViewController];
    
    return YES;
}


#pragma mark - UI State
-(void)toggleSymbol {
    symbolLocal = !symbolLocal;
    
    [transactionsViewController setText];
    [[transactionsViewController tableView] reloadData];
}

-(void)showBusy {
    if (tasks == 0) {
        [_window addSubview:busyView];
        [busyView fadeIn];
    }
}

-(void)startTask:(Task)task {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        switch (task) {
            case TaskGeneratingWallet:
                [self showBusy];
                
                [busyLabel setText:@"generating wallet"];
                break;
            case TaskSaveWallet:
                [self showBusy];
                
                [busyLabel setText:@"saving wallet"];
                
                break;
            case TaskLoadUnconfirmed:
                [self showBusy];
                
                [busyLabel setText:@"loading unconfirmed"];
                
                break;
            case TaskGetWallet:
                if (wallet == NULL) {
                    [self showBusy];
                }
                
                [busyLabel setText:@"downloading wallet"];
                
                break;
                
            case TaskGetMultiAddr:
                if (transactionsViewController.data == NULL) {
                    [self showBusy];
                }
                
                [busyLabel setText:@"downloading transactions"];
                
                break;
            case TaskLoadExternalURL:
                [self showBusy];
                
                [busyLabel setText:@"loading page"];
                
                break;
        }
        
        if (tasks == 0) {
            [activity startAnimating];
        }
        
        ++tasks;
        
        [self setStatus];
    });
}

-(void)finishTask {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (tasks > 0) {
            --tasks;
        }
        
        if (tasks == 0) {
            [busyView fadeOut];
            
            [activity stopAnimating];
        }
        
        [self setStatus];
    });
}


-(void)setStatus {
    [powerButton setHighlighted:FALSE];
    
    if (tasks > 0) {
        [powerButton setEnabled:FALSE];
    } else {
        [powerButton setEnabled:TRUE];
        
#warning Reimplement Status icon
        //if ([webSocket readyState] != ReadyStateOpen) {
        //    [powerButton setHighlighted:TRUE];
        //}
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
            [alert release];
        }
    });
}

#pragma mark File IO

-(NSData*)readFromFileName:(NSString *)fileName  {
        
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	
    // the path to write file
    NSString * documentPath = [documentsDirectory stringByAppendingPathComponent:fileName];
        
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentPath])  {
        [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory
                                  withIntermediateDirectories:YES 
                                                   attributes:nil 
                                                        error:NULL];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:documentPath]) {
        return [[[NSData alloc] initWithContentsOfFile:documentPath] autorelease];
    }

    return NULL;
}

- (BOOL)writeToFile:(NSData *)data fileName:(NSString *)fileName 
{   
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	
    // the path to write file
    NSString *documentPath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    
    NSLog(@"Write to bytes %d file %@", [data length], documentPath);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentPath])  {
        [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory
                                  withIntermediateDirectories:YES 
                                                   attributes:nil 
                                                        error:NULL];
    }
    
    NSError * error = nil;
    
    [data writeToFile:documentPath options:0 error:&error];
    
    if (error) {
        NSLog(@"Error writing file %@", error);
        
        return FALSE;
    }
    
    return TRUE;
}


-(void)didGenerateNewWallet:(Wallet*)_wallet password:(NSString*)password {
    
    [self forgetWallet];

    self.wallet = _wallet;
    
    [[NSUserDefaults standardUserDefaults] setObject:wallet.guid forKey:@"guid"];
    [[NSUserDefaults standardUserDefaults] setObject:wallet.sharedKey forKey:@"sharedKey"];
    [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    receiveViewController.wallet = _wallet;
    sendViewController.wallet = _wallet;
}

-(void)walletDidLoad:(Wallet *)_wallet {      
    NSLog(@"walletDidLoad");

    [self setAccountData:wallet.guid sharedKey:wallet.sharedKey password:wallet.password];
    
    _tempLastKeyCount = [_wallet.keys count];
    
    receiveViewController.wallet = _wallet;
    sendViewController.wallet = _wallet;
    [accountViewController loadWebView];
}

-(void)didGetMultiAddressResponse:(MulitAddressResponse*)response {
    self.latestResponse = response;

    transactionsViewController.data = response;
}

-(void)didSetLatestBlock:(LatestBlock*)block {
    transactionsViewController.latestBlock = block;
}

-(void)walletFailedToDecrypt:(Wallet*)_wallet {    
    
    _wallet.password = nil;
    
    //Clear the password and refetch the wallet data
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"password"];
    
    //Cleare the checksum cache incase it has
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"checksum_cache"];

    [self showModal:mainPasswordView];
    
    [mainPasswordTextField becomeFirstResponder];
}

-(void)didGetWalletData:(NSData *)data  {
    if ([self password]) {
        self.wallet = [[[Wallet alloc] initWithData:data password:[self password]] autorelease];

        wallet.delegate = self;
    } else {
        [self showModal:mainPasswordView];
        
        [mainPasswordTextField becomeFirstResponder];
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
    
}

-(void)playBeepSound {
    
	if (beepSoundID == 0) {
		AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"]], &beepSoundID);
	}
	
	AudioServicesPlaySystemSound(beepSoundID);		
}

-(void)playAlertSound {
    
	if (alertSoundID == 0) {
		//Find the Alert Sound
		NSString * alert_sound = [[NSBundle mainBundle] pathForResource:@"alert-received" ofType:@"wav"];
		
		//Create the system sound
		AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath: alert_sound], &alertSoundID);
	}
	
	AudioServicesPlaySystemSound(alertSoundID);		
}

//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{	
}

// Only gets called when displaying a transaction hash
-(void)pushWebViewController:(NSString*)url {
    webViewController = [[WebViewController alloc] init];
    [webViewController viewDidLoad]; // ??

    [tabViewController setActiveViewController:webViewController animated:YES index:-1];

    [webViewController loadURL:url];
}

- (NSMutableDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [[[NSMutableDictionary alloc] initWithCapacity:6] autorelease];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [dict setObject:val forKey:key];
    }
    return dict;
}

-(NSDictionary*)parseURI:(NSString*)urlString {
    
    if (![urlString hasPrefix:@"bitcoin:"]) {
        return [NSDictionary dictionaryWithObject:urlString forKey:@"address"];
    }
        
    NSString * replaced = [[urlString stringByReplacingOccurrencesOfString:@"bitcoin:" withString:@"bitcoin://"] stringByReplacingOccurrencesOfString:@"////" withString:@"//"];
    
    NSLog(@"%@", replaced);
    
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
    
    [sendViewController setToAddress:addr];
    
    [sendViewController setAmount:amount];

    return YES;
}

-(void)didSubmitTransaction {
    [app closeModal];
}

-(TabViewcontroller*)tabViewController {
    return tabViewController;
}

-(IBAction)closeModalClicked:(id)sender {
    [self closeModal];
}

-(void)closeModal {
    
    [modalView removeFromSuperview]; 
    [modalContentView removeFromSuperview]; 

    CATransition *animation = [CATransition animation]; 
    [animation setDuration:ANIMATION_DURATION];
    [animation setType:kCATransitionFade]; 
        
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    
    [[_window layer] addAnimation:animation forKey:@"HideModal"]; 
        
    if ([modalDelegate respondsToSelector:@selector(didDismissModal)])
        [modalDelegate didDismissModal];
        
    self.modalContentView = nil;
    self.modalView = nil;
    self.modalDelegate = nil;
}

-(IBAction)secondPasswordClicked:(id)sender {
    NSString * password = secondPasswordTextField.text;
        
    if (![[[wallet.sharedKey stringByAppendingString:password] SHA256:10] isEqualToString:wallet.dPasswordHash]) {
        [app standardNotify:@"Second Password Incorrect"];
    } else {
        wallet.secondPassword = password;
        
        [app closeModal];
    }
    
    secondPasswordTextField.text = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
    
    return YES;
}

-(BOOL)getSecondPasswordBlocking {
    
    @try {
        if (![wallet isDoubleEncrypted])
            return YES;
        
        if (wallet.secondPassword)
            return YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                [app showModal:secondPasswordView];
            
                [secondPasswordTextField becomeFirstResponder];
            } @catch (NSException * e) {
                [UncaughtExceptionHandler logException:e];
            }
        });
        
        usleep(50000);

        while (app.modalView) {
            usleep(20000);
        }
        
        if (wallet.secondPassword)
            return TRUE;
        
        return FALSE;
    } @catch (NSException * e) {
        [UncaughtExceptionHandler logException:e];
    }
}

-(void)showModal:(UIView*)contentView {

    @try {
        if (modalView) {
//            NSLog(@"closing modal..already visible");
            [self closeModal];
        }
        
        [[NSBundle mainBundle] loadNibNamed:@"ModalView" owner:self options:nil];
        [modalContentView addSubview:contentView];
        
        contentView.frame = CGRectMake(0, 0, modalContentView.frame.size.width, modalContentView.frame.size.height);
        [_window.rootViewController.view addSubview:modalView];
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
        NSLog(@"%@", e);
    }
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

-(void)didDismissModal {
    [readerView stop];
    
    self.readerView = nil;
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
    
    self.wallet = [[Wallet alloc] initWithGuid:guid password:password];
    
    self.wallet.delegate = app;
}

- (void) readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img {
    
    // do something uselful with results
    for(ZBarSymbol *sym in syms) {        
        Wallet * pairingWallet = [[Wallet alloc] initWithEncryptedQRString:sym.data];

        NSLog(@"pairingWallet: %@", pairingWallet);

#warning incomplete?
//        [self setAccountData:guid sharedKey:sharedKey password:password];
        
        [readerView stop];
        
        [app closeModal];
        
        break;
    }
    
    self.readerView = nil;
}

-(IBAction)scanAccountQRCodeclicked:(id)sender {
    
    if ([self isZBarSupported]) {
        self.readerView = [[ZBarReaderView new] autorelease];
        
        [app showModal:readerView];

        self.modalDelegate = self;
        
        [readerView start];
        
        [readerView setReaderDelegate:self];
    } else {
        [self showModal:manualView];
    }
}

-(void)logout {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"password"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSFileManager defaultManager] removeItemAtPath:MultiaddrCacheFile error:nil];

    self.wallet = nil;
    self.latestResponse = nil;
    [transactionsViewController setData:nil];
    [receiveViewController setWallet:nil];
    [accountViewController emptyWebView];
}

-(void)forgetWallet {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"guid"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sharedKey"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"password"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];   
    
    [[NSFileManager defaultManager] removeItemAtPath:WalletCachefile error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:MultiaddrCacheFile error:nil];

    self.wallet = nil;
    self.latestResponse = nil;
    [transactionsViewController setData:nil];
    [receiveViewController setWallet:nil];
}

#pragma mark - Show Screens

// Modal menu
-(void)showWelcome {
    if ([self password]) {
        [pairLogoutButton setTitle:@"Logout" forState:UIControlStateNormal];
    } else if ([self guid] || [self sharedKey]) {
        [pairLogoutButton setTitle:@"Forget Details" forState:UIControlStateNormal];
    } else {
        [pairLogoutButton setTitle:@"Pair Device" forState:UIControlStateNormal];
    }
    
    [app showModal:welcomeView];
}

-(void)showSendCoins {
    
    if (!sendViewController) {
        sendViewController = [[SendViewController alloc] initWithNibName:@"SendCoins" bundle:[NSBundle mainBundle]];
        
        [sendViewController viewDidLoad];
    }
    
    sendViewController.wallet = wallet;
    
    [tabViewController setActiveViewController:sendViewController  animated:TRUE index:2];
}

- (void)showPinModal
{
    // if pin exists - verify
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"pin"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            PEPinEntryController *c = [PEPinEntryController pinVerifyController];
            c.navigationBarHidden = YES;
            c.pinDelegate = self;
            
            [_window.rootViewController presentViewController:c animated:YES completion:nil];
        });
    }
    // no pin - create
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            PEPinEntryController *c = [PEPinEntryController pinCreateController];
            c.navigationBarHidden = YES;
            c.pinDelegate = self;
            
            [_window.rootViewController presentViewController:c animated:YES completion:nil];
        });
    }
}

#pragma mark - Actions

-(IBAction)changePinClicked:(id)sender {
    PEPinEntryController *c = [PEPinEntryController pinChangeController];
    c.pinDelegate = self;
    c.navigationBarHidden = YES;
    [self.tabViewController presentViewController:c animated:YES completion:nil];
}

-(IBAction)powerClicked:(id)sender {
    [self showWelcome];
}

-(IBAction)signupClicked:(id)sender {
    
    [app showModal:newAccountView];
}

-(IBAction)loginClicked:(id)sender {
    
    if ([self password]) {
        [self logout];
        
        [app closeModal];
    } else if ([self guid] || [self sharedKey]) {
        [self forgetWallet];
        
        [app closeModal];
    } else {
        [app showModal:pairingInstructionsView];
    }
}

-(IBAction)receiveCoinClicked:(UIButton *)sender {
    if (!receiveViewController) {
        receiveViewController = [[ReceiveCoinsViewController alloc] initWithNibName:@"ReceiveCoins" bundle:[NSBundle mainBundle]];
        
        [receiveViewController viewDidLoad];
    }
    
    receiveViewController.wallet = wallet;
    
    [tabViewController setActiveViewController:receiveViewController animated:TRUE index:1];
}

-(IBAction)transactionsClicked:(UIButton *)sender {
    [tabViewController setActiveViewController:transactionsViewController animated:TRUE index:0];
}

-(IBAction)sendCoinsClicked:(UIButton *)sender {
    [self showSendCoins];
}

-(IBAction)infoClicked:(UIButton *)sender {
    if (!accountViewController) {
        accountViewController = [[AccountViewController alloc] initWithNibName:@"AccountViewController" bundle:[NSBundle mainBundle]];
        
        [accountViewController viewDidLoad];
    }
    
    [tabViewController setActiveViewController:accountViewController animated:TRUE index:3];
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
        self.wallet = [[Wallet alloc] initWithGuid:guid sharedKey:sharedKey password:password];
    }
    
    mainPasswordTextField.text = nil;
    
    [app closeModal];
}

-(IBAction)refreshClicked:(id)sender {
    if (![self guid] || ![self sharedKey]) {
        [app showWelcome];
        return;
    }
    
    if (wallet.password) {
        [self.wallet getHistory];
    } else {
        [self walletFailedToDecrypt:wallet];
    }
}

-(IBAction)modalBackgroundClicked:(id)sender {
    [modalView endEditing:FALSE];
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
			[tabViewController dismissViewControllerAnimated:YES completion:^{
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
    
    NSLog(@"Saved new pin");
    
	// Update your info to new pin code
	[tabViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)pinEntryControllerDidCancel:(PEPinEntryController *)c
{
	NSLog(@"Pin change cancelled!");
	[tabViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Format helpers

-(NSString*)formatMoney:(uint64_t)value localCurrency:(BOOL)fsymbolLocal {
    if (fsymbolLocal && latestResponse.symbol.conversion) {
        @try {
            BOOL negative = false;
            
            NSDecimalNumber * number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:value] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithDouble:(double)latestResponse.symbol.conversion]];
            
            if ([number compare:[NSNumber numberWithInt:0]] < 0) {
                number = [number decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"-1"]];
                negative = TRUE;
            }
            
            if (negative)
                return [@"-" stringByAppendingString:[latestResponse.symbol.symbol stringByAppendingString:[btcFromatter stringFromNumber:number]]];
            else
                return [latestResponse.symbol.symbol stringByAppendingString:[btcFromatter stringFromNumber:number]];
            
        } @catch (NSException * e) {
            NSLog(@"%@", e);
        }
    }
    
    
    NSDecimalNumber * number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:value] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithDouble:(double)SATOSHI]];
    
    NSString * string = [btcFromatter stringFromNumber:number];
    
    if ([string length] >= 8) {
        string = [string substringToIndex:8];
    }
    
    return [string stringByAppendingString:@" BTC"];
}

-(NSString*)formatMoney:(uint64_t)value {
    return [self formatMoney:value localCurrency:symbolLocal];
}

@end
