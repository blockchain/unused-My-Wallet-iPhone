/*
 * 
 * Copyright (c) 2012, Ben Reeves. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */

#import <AudioToolbox/AudioToolbox.h>

#import "Wallet.h"
#import "MultiAddressResponse.h"
#import "TabViewController.h"
#import "PEPinEntryController.h"
#import "BCModalView.h"
#import "ECSlidingViewController.h"

#define SATOSHI 100000000
#define LOADING_TEXT_NOTIFICATION_KEY @"SetLoadingText"
#define WebROOT @"https://blockchain.info/"
#define MULTI_ADDR_TIME 60.0f // 1 Minute

#define PIN_API_STATUS_CODE_DELETED 1
#define PIN_API_STATUS_PIN_INCORRECT 2
#define PIN_API_STATUS_OK 0
#define PIN_API_STATUS_UNKNOWN 3
#define PIN_API_STATUS_DUPLICATE_KEY 4

#define PIN_PBKDF2_ITERATIONS 1 // This does not need to be large because the key is already 256 bits

@class TransactionsViewController, Wallet, BCFadeView, ReceiveCoinsViewController, SendViewController, BCCreateWalletView, BCManualPairView, MultiAddressResponse, PairingCodeParser, MerchantMapViewController, BCWebViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate, WalletDelegate, PEPinEntryControllerDelegate> {
    Wallet *wallet;
    
    SystemSoundID alertSoundID;
    SystemSoundID beepSoundID;
    SystemSoundID dingSoundID;
    
    IBOutlet BCFadeView *busyView;
    IBOutlet UILabel *busyLabel;
    
    IBOutlet BCCreateWalletView *newAccountView;
    IBOutlet BCModalContentView *pairingInstructionsView;
    IBOutlet BCManualPairView *manualPairView;
    
    BOOL validateSecondPassword;
    IBOutlet UILabel *secondPasswordDescriptionLabel;
    IBOutlet UIView *secondPasswordView;
    IBOutlet UITextField *secondPasswordTextField;
    
    IBOutlet UIView *mainPasswordView;
    IBOutlet UITextField *mainPasswordTextField;
    
    @public
    
    BOOL symbolLocal;
}

@property (strong, nonatomic) IBOutlet ECSlidingViewController *slidingViewController;
@property (strong, nonatomic) IBOutlet TabViewcontroller *tabViewController;
@property (strong, nonatomic) IBOutlet TransactionsViewController *transactionsViewController;
@property (strong, nonatomic) IBOutlet ReceiveCoinsViewController *receiveViewController;
@property (strong, nonatomic) IBOutlet SendViewController *sendViewController;
@property (strong, nonatomic) IBOutlet MerchantMapViewController *merchantViewController;
@property (strong, nonatomic) IBOutlet BCWebViewController *bcWebViewController;

@property (nonatomic) BOOL showEmailWarning;

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundUpdateTask;

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (strong, nonatomic) Wallet *wallet;
@property (strong, nonatomic) MultiAddressResponse *latestResponse;
@property (nonatomic, strong) NSString *loadingText;

@property (strong, nonatomic) IBOutlet BCModalView *modalView;
@property (strong, nonatomic) NSMutableArray *modalChain;

// PIN Entry
@property (nonatomic, strong) PEPinEntryController *pinEntryViewController;
@property (nonatomic, copy) void (^pinViewControllerCallback)(BOOL);
@property (nonatomic, assign) NSUInteger lastEnteredPIN;

@property(nonatomic, strong) NSNumberFormatter *btcFormatter;
@property(nonatomic, strong) NSNumberFormatter *localCurrencyFormatter;

- (void)setAccountData:(NSString*)guid sharedKey:(NSString*)sharedKey;

- (void)playBeepSound;
- (void)playAlertSound;

- (TabViewcontroller*)tabViewController;
- (TransactionsViewController*)transactionsViewController;

- (void)forgetWallet;
- (void)toggleSideMenu;

- (NSString *)guid;
- (NSString *)sharedKey;

- (void)swipeLeft;
- (void)swipeRight;

// BC Modal
- (void)showModalWithContent:(UIView *)contentView closeType:(ModalCloseType)closeType headerText:(NSString *)headerText;
- (void)showModalWithContent:(UIView *)contentView closeType:(ModalCloseType)closeType headerText:(NSString *)headerText onDismiss:(void (^)())onDismiss onResume:(void (^)())onResume;
- (void)showModalWithContent:(UIView *)contentView closeType:(ModalCloseType)closeType showHeader:(BOOL)showHeader headerText:(NSString *)headerText onDismiss:(void (^)())onDismiss onResume:(void (^)())onResume;
- (void)closeModalWithTransition:(NSString *)transition;

- (NSDictionary*)parseURI:(NSString*)string;

// Wallet Delegate
- (void)didSetLatestBlock:(LatestBlock*)block;
- (void)walletDidLoad;
- (void)walletFailedToDecrypt;

// Display a message
- (void)standardNotify:(NSString*)message;
- (void)standardNotify:(NSString*)message delegate:(id)fdelegate;
- (void)standardNotify:(NSString*)message title:(NSString*)title delegate:(id)fdelegate;

// Busy view with loading text
- (void)showBusyViewWithLoadingText:(NSString *)text;
- (void)updateBusyViewLoadingText:(NSString *)text;
- (void)hideBusyView;

// Request Second Password From User
- (void)getSecondPassword:(void (^)(NSString *))success error:(void (^)(NSString *))error;
- (void)getPrivateKeyPassword:(void (^)(NSString *))success error:(void (^)(NSString *))error;

- (NSString*)formatMoney:(uint64_t)value;
- (NSString*)formatMoney:(uint64_t)value localCurrency:(BOOL)fsymbolLocal;

- (void)reload;
- (void)toggleSymbol;
  
- (void)pushWebViewController:(NSString*)url;

- (void)showSendCoins;

- (IBAction)receiveCoinClicked:(UIButton *)sender;
- (IBAction)transactionsClicked:(UIButton *)sender;
- (IBAction)sendCoinsClicked:(UIButton *)sender;
- (IBAction)merchantClicked:(UIButton *)sender;
- (IBAction)QRCodebuttonClicked:(id)sender;
- (IBAction)forgetWalletClicked:(id)sender;
- (IBAction)menuClicked:(id)sender;
- (IBAction)scanAccountQRCodeclicked:(id)sender;
- (IBAction)secondPasswordClicked:(id)sender;
- (IBAction)mainPasswordClicked:(id)sender;
- (IBAction)balanceTextClicked:(id)sender;

- (IBAction)newsClicked:(id)sender;
- (IBAction)accountSettingsClicked:(id)sender;
- (IBAction)changePINClicked:(id)sender;
- (IBAction)logoutClicked:(id)sender;

- (void)clearPin;
- (void)showPinModalAsView:(BOOL)asView;
- (BOOL)isPINSet;

@end

extern AppDelegate *app;
