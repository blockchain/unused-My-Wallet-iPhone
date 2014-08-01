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

#pragma mark test watch only

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

#import "Wallet.h"
#import "MultiAddressResponse.h"
#import "TabViewController.h"
#import "ZBarSDK.h"
#import "PEPinEntryController.h"
#import "UIModalView.h"

#define SATOSHI 100000000
#define LOADING_TEXT_NOTIFICAITON_KEY @"SetLoadingText"
#define WebROOT @"https://blockchain.info/"
#define MULTI_ADDR_TIME 60.0f //1 Minute

#define PIN_API_STATUS_CODE_DELETED 1
#define PIN_API_STATUS_PIN_INCORRECT 2
#define PIN_API_STATUS_OK 0
#define PIN_API_STATUS_UNKNOWN 3
#define PIN_API_STATUS_DUPLICATE_KEY 4

#define PIN_PBKDF2_ITERATIONS 1 //This does not need to be large because the key is already 256 bits

@class TransactionsViewController, Wallet, BCFadeView, ReceiveCoinsViewController, AccountViewController, SendViewController, WebViewController, NewAccountView, MulitAddressResponse, PairingCodeParser, MerchantViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate, WalletDelegate, PEPinEntryControllerDelegate> {
    Wallet * wallet;
    
    SystemSoundID alertSoundID;
    SystemSoundID beepSoundID;
    SystemSoundID dingSoundID;

    IBOutlet UIActivityIndicatorView * activity;
    IBOutlet BCFadeView * busyView;
    IBOutlet UILabel * busyLabel;
    IBOutlet UIButton * powerButton;

    IBOutlet UIView * welcomeView;
    IBOutlet NewAccountView * newAccountView;
    IBOutlet UIView * pairingInstructionsView;

    IBOutlet UIButton * welcomeButton1;
    IBOutlet UIButton * welcomeButton2;
    IBOutlet UIButton * welcomeButton3;
    
    BOOL validateSecondPassword;
    IBOutlet UILabel * secondPasswordDescriptionLabel;
    IBOutlet UILabel * welcomeLabel;
    IBOutlet UILabel * welcomeInstructionsLabel;
    IBOutlet UIView * secondPasswordView;
    IBOutlet UITextField * secondPasswordTextField;
    
    IBOutlet UIView * mainPasswordView;
    IBOutlet UITextField * mainPasswordTextField;

    IBOutlet UIView * manualView;
    IBOutlet UITextField * manualIdentifier;
    IBOutlet UITextField * manualSharedKey;
    IBOutlet UITextField * manualPassword;
    
    @public
    
    BOOL symbolLocal;
}

@property (strong, nonatomic) IBOutlet TabViewcontroller * tabViewController;
@property (strong, nonatomic) IBOutlet TransactionsViewController * transactionsViewController;
@property (strong, nonatomic) IBOutlet ReceiveCoinsViewController * receiveViewController;
@property (strong, nonatomic) IBOutlet SendViewController * sendViewController;
@property (strong, nonatomic) IBOutlet AccountViewController * accountViewController;
@property (strong, nonatomic) IBOutlet MerchantViewController * merchantViewController;

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundUpdateTask;

@property (strong, nonatomic) WebViewController * webViewController;

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (strong, nonatomic) Wallet * wallet;
@property (strong, nonatomic) MulitAddressResponse * latestResponse;
@property (nonatomic, strong) NSString * loadingText;

@property (nonatomic) BOOL disableBusyView;

@property (strong, nonatomic) IBOutlet MyUIModalView * modalView;
@property (strong, nonatomic) NSMutableArray * modalChain;

//PIN Entry
@property (nonatomic, strong) PEPinEntryController * pinEntryViewController;
@property (nonatomic, copy) void (^pinViewControllerCallback)(BOOL);
@property (nonatomic, assign) NSUInteger lastEnteredPIN;

@property(nonatomic, strong) NSNumberFormatter * btcFormatter;
@property(nonatomic, strong) NSNumberFormatter * localCurrencyFormatter;

-(IBAction)manualPairClicked:(id)sender;
-(void)setAccountData:(NSString*)guid sharedKey:(NSString*)sharedKey;

-(void)playBeepSound;
-(void)playAlertSound;

-(TabViewcontroller*)tabViewController;
-(TransactionsViewController*)transactionsViewController;

-(void)forgetWallet;
-(void)showWelcome;

-(NSString*)guid;
-(NSString*)sharedKey;

-(void)swipeLeft;
-(void)swipeRight;

//Simple Modal UIVIew
-(void)showModal:(UIView*)contentView isClosable:(BOOL)_isClosable onDismiss:(void (^)())onDismiss onResume:(void (^)())onResume;
-(void)showModal:(UIView*)contentView isClosable:(BOOL)_isClosable;
-(void)closeModal;

-(NSDictionary*)parseURI:(NSString*)string;

//Wallet Delegate
-(void)didSetLatestBlock:(LatestBlock*)block;
-(void)walletDidLoad;
-(void)walletFailedToDecrypt;
-(void)networkActivityStart;
-(void)networkActivityStop;

//Display a message
- (void)standardNotify:(NSString*)message;
- (void)standardNotify:(NSString*)message delegate:(id)fdelegate;
- (void)standardNotify:(NSString*)message title:(NSString*)title delegate:(id)fdelegate;

//Request Second Password From User
-(void)getSecondPassword:(void (^)(NSString *))success error:(void (^)(NSString *))error;
-(void)getPrivateKeyPassword:(void (^)(NSString *))success error:(void (^)(NSString *))error;

-(NSString*)formatMoney:(uint64_t)value;
-(NSString*)formatMoney:(uint64_t)value localCurrency:(BOOL)fsymbolLocal;

-(void)toggleSymbol;
  
-(void)pushWebViewController:(NSString*)url;

-(void)showSendCoins;

-(IBAction)receiveCoinClicked:(UIButton *)sender;
-(IBAction)transactionsClicked:(UIButton *)sender;
-(IBAction)sendCoinsClicked:(UIButton *)sender;
-(IBAction)merchantClicked:(UIButton *)sender;
-(IBAction)accountSettingsClicked:(UIButton *)sender;
-(IBAction)forgetWalletClicked:(id)sender;
-(IBAction)powerClicked:(id)sender;
-(IBAction)scanAccountQRCodeclicked:(id)sender;
-(IBAction)secondPasswordClicked:(id)sender;
-(IBAction)mainPasswordClicked:(id)sender;
-(IBAction)refreshClicked:(id)sender;
-(IBAction)balanceTextClicked:(id)sender;

//WelcomeMenu
-(IBAction)welcomeButton1Clicked:(id)sender;
-(IBAction)welcomeButton2Clicked:(id)sender;
-(IBAction)welcomeButton3Clicked:(id)sender;

-(void)setStatus;
-(void)clearPin;
-(void)showPinModal;
-(BOOL)isPINSet;

@end

extern AppDelegate * app;