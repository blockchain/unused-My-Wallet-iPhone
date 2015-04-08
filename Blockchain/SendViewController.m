//
//  SendViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 17/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "SendViewController.h"
#import "Wallet.h"
#import "AppDelegate.h"
#import "BCAddressSelectionView.h"
#import "TabViewController.h"
#import "UncaughtExceptionHandler.h"
#import "UITextField+Blocks.h"
#import "UIAlertView+Blocks.h"
#import "LocalizationConstants.h"
#import "TransactionsViewController.h"

@implementation SendViewController

AVCaptureSession *captureSession;
AVCaptureVideoPreviewLayer *videoPreviewLayer;

float containerOffset;

uint64_t amountInSatoshi = 0.0;

uint64_t availableAmount = 0.0;

#pragma mark - Lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    sendProgressModalText.text = nil;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:LOADING_TEXT_NOTIFICATION_KEY object:nil queue:nil usingBlock:^(NSNotification * notification) {
        
        sendProgressModalText.text = [notification object];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LOADING_TEXT_NOTIFICATION_KEY object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect frame = containerView.frame;
    containerOffset = (app.window.frame.size.height - frame.size.height - DEFAULT_HEADER_HEIGHT - DEFAULT_FOOTER_HEIGHT)/3;
    frame.origin.y = containerOffset;
    containerView.frame = frame;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [toFieldContainerField setShouldBegindEditingBlock:^BOOL(UITextField * field) {
        return FALSE;
    }];
    
    self.fromAddress = @"";
    if ([app.wallet didUpgradeToHd]) {
        // Default setting: send from default account
        self.sendFromAddress = false;
        
        int defaultAccountIndex = [app.wallet getDefaultAccountIndex];
        self.fromAccount = defaultAccountIndex;
    }
    else {
        // Default setting: send from any address
        self.sendFromAddress = true;
    }

    self.sendToAddress = true;
    
    amountKeyboardAccessoryView.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
    amountKeyboardAccessoryView.layer.borderColor = [[UIColor colorWithRed:181.0f/255.0f green:185.0f/255.0f blue:189.0f/255.0f alpha:1.0f] CGColor];
    
    amountField.inputAccessoryView = amountKeyboardAccessoryView;
    
    [toField setReturnKeyType:UIReturnKeyDone];
    
    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width,
                                 app.window.frame.size.height - DEFAULT_HEADER_HEIGHT - DEFAULT_FOOTER_HEIGHT);
    
    [self reload];
}

- (void)reload
{
    if (![app.wallet isInitialized] || !app.latestResponse) {
        return;
    }
    
#ifdef DISABLE_MULTIPLE_ACCOUNTS
    // If we only have one account and no legacy addresses -> can't change from address
    if ([app.wallet didUpgradeToHd] && ![app.wallet hasLegacyAddresses] && [app.wallet addressBook].count == 0) {
        [addressBookButton setHidden:YES];
    }
    else {
        [addressBookButton setHidden:NO];
    }
#endif
    
    // Populate address field from URL handler if available.
    if (self.initialToAddressString && toField != nil) {
        self.sendToAddress = true;
        self.toAddress = self.initialToAddressString;
        DLog(@"toAddress: %@", self.toAddress);
        
        toField.text = [self labelForLegacyAddress:self.toAddress];
        self.initialToAddressString = nil;
    }
    
    // Update account/address labels in case they changed
    // Update available amount
    if (self.sendFromAddress) {
        if (self.fromAddress.length == 0) {
            selectAddressTextField.text = BC_STRING_ANY_ADDRESS;
            availableAmount = [app.wallet getTotalBalanceForActiveLegacyAddresses];
        }
        else {
            selectAddressTextField.text = [self labelForLegacyAddress:self.fromAddress];
            availableAmount = [app.wallet getLegacyAddressBalance:self.fromAddress];
        }
    }
    else {
        selectAddressTextField.text = [app.wallet getLabelForAccount:self.fromAccount];
        availableAmount = [app.wallet getBalanceForAccount:self.fromAccount];
    }
    
    if (self.sendToAddress) {
        toField.text = [self labelForLegacyAddress:self.toAddress];
    }
    else {
        toField.text = [app.wallet getLabelForAccount:self.toAccount];
    }
    
    if (app->symbolLocal && app.latestResponse.symbol_local && app.latestResponse.symbol_local.conversion > 0) {
        [btcCodeButton setTitle:app.latestResponse.symbol_local.code forState:UIControlStateNormal];
        displayingLocalSymbol = TRUE;
    } else if (app.latestResponse.symbol_btc) {
        [btcCodeButton setTitle:app.latestResponse.symbol_btc.symbol forState:UIControlStateNormal];
        displayingLocalSymbol = FALSE;
    }
    
    [self updateAmountField];
}

- (void)reset
{
    [sendPaymentButton setEnabled:YES];
}

#pragma mark - Payment

- (void)reallyDoPayment
{
    transactionProgressListeners *listener = [[transactionProgressListeners alloc] init];
    
    listener.on_start = ^() {
//        app.disableBusyView = TRUE;
//        
//        sendProgressModalText.text = BC_STRING_PLEASE_WAIT;
//        
//        [app showModalWithContent:sendProgressModal closeType:ModalCloseTypeNone];
    };
    
    listener.on_begin_signing = ^() {
        sendProgressModalText.text = BC_STRING_SIGNING_INPUTS;
    };
    
    listener.on_sign_progress = ^(int input) {
        DLog(@"Signing input: %d", input);
        sendProgressModalText.text = [NSString stringWithFormat:BC_STRING_SIGNING_INPUT, input];
    };
    
    listener.on_finish_signing = ^() {
        sendProgressModalText.text = BC_STRING_FINISHED_SIGNING_INPUTS;
    };
    
    listener.on_success = ^() {
        [app playBeepSound];
        
        [app standardNotify:BC_STRING_PAYMENT_SENT title:BC_STRING_SUCCESS delegate:nil];
        
        [sendProgressActivityIndicator stopAnimating];
        
        [sendPaymentButton setEnabled:TRUE];
        
        // Reset fields
        self.fromAddress = @"";
        if ([app.wallet didUpgradeToHd]) {
            // Default setting: send from default account
            self.sendFromAddress = false;
            int defaultAccountIndex = [app.wallet getDefaultAccountIndex];
            selectAddressTextField.text = [app.wallet getLabelForAccount:defaultAccountIndex];
            self.fromAccount = defaultAccountIndex;
            
            availableAmount = [app.wallet getBalanceForAccount:defaultAccountIndex];
        }
        else {
            // Default setting: send from any address
            self.sendFromAddress = true;
            selectAddressTextField.text = BC_STRING_ANY_ADDRESS;
            
            availableAmount = [app.wallet getTotalBalanceForActiveLegacyAddresses];
        }
        
        self.sendToAddress = true;
        
        toField.text = nil;
        amountField.text = nil;
        self.toAddress = @"";
        amountInSatoshi = 0.0;
        [self doCurrencyConversion];
        
        // Close transaction modal, go to transactions view, scroll to top and animate new transaction
        [app closeModalWithTransition:kCATransitionFade];
        [app.transactionsViewController animateNextCellAfterReload];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [app transactionsClicked:nil];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [app.transactionsViewController.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
            
            [app.wallet loading_start_get_history];
        });
    };
    
    listener.on_error = ^(NSString* error) {
        if (error && error.length != 0) {
            [app standardNotify:error];
        }
        
        [sendProgressActivityIndicator stopAnimating];
        
        [sendPaymentButton setEnabled:TRUE];
        
        [app closeModalWithTransition:kCATransitionFade];
    };
    
    [sendPaymentButton setEnabled:FALSE];
    
    [sendProgressActivityIndicator startAnimating];
    
    sendProgressModalText.text = BC_STRING_SENDING_TRANSACTION;
    
    [app showModalWithContent:sendProgressModal closeType:ModalCloseTypeNone headerText:BC_STRING_SENDING_TRANSACTION];
    
    NSString *amountString = [[NSNumber numberWithLongLong:amountInSatoshi] stringValue];
    
    DLog(@"Sending uint64_t %llu Satoshi (String value: %@)", amountInSatoshi, amountString);
    
    // Different ways of sending (from/to address or account
    if (self.sendFromAddress && self.sendToAddress) {
        DLog(@"From: %@", self.fromAddress);
        DLog(@"To: %@", self.toAddress);
        
        [app.wallet sendPaymentFromAddress:self.fromAddress toAddress:self.toAddress satoshiValue:amountString listener:listener];
    }
    else if (self.sendFromAddress && !self.sendToAddress) {
        DLog(@"From: %@", self.fromAddress);
        DLog(@"To account: %d", self.toAccount);
        
        [app.wallet sendPaymentFromAddress:self.fromAddress toAccount:self.toAccount satoshiValue:amountString listener:listener];
    }
    else if (!self.sendFromAddress && self.sendToAddress) {
        DLog(@"From account: %d", self.fromAccount);
        DLog(@"To: %@", self.toAddress);
        
        [app.wallet sendPaymentFromAccount:self.fromAccount toAddress:self.toAddress satoshiValue:amountString listener:listener];
    }
    else if (!self.sendFromAddress && !self.sendToAddress) {
        DLog(@"From account: %d", self.fromAccount);
        DLog(@"To account: %d", self.toAccount);
        
        [app.wallet sendPaymentFromAccount:self.fromAccount toAccount:self.toAccount satoshiValue:amountString listener:listener];
    }
}

- (uint64_t)getInputAmountInSatoshi
{
    NSString *amountString = [amountField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
    
    if (displayingLocalSymbol) {
        return app.latestResponse.symbol_local.conversion * [amountString doubleValue];
    } else {
        return [app.wallet parseBitcoinValue:amountString];
    }
}

- (void)confirmPayment
{
    NSString *amountBTCString   = [app formatMoney:amountInSatoshi localCurrency:FALSE];
    NSString *amountLocalString = [app formatMoney:amountInSatoshi localCurrency:TRUE];
    
    NSMutableString *messageString = [NSMutableString stringWithFormat:BC_STRING_CONFIRM_PAYMENT_OF, amountBTCString, amountLocalString, self.toAddress];
    
    BCAlertView *alert = [[BCAlertView alloc] initWithTitle:BC_STRING_CONFIRM_PAYMENT
                                                    message:messageString
                                                   delegate:self
                                          cancelButtonTitle:BC_STRING_NO
                                          otherButtonTitles:BC_STRING_YES, nil];
    
    alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            [self reallyDoPayment];
        }
    };
    
    [alert show];
}

#pragma mark - UI Helpers

- (void)updateAmountField
{
    if (amountInSatoshi == 0) {
        amountField.text = nil;
    }
    else if (displayingLocalSymbol) {
        @try {
            NSDecimalNumber *number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:amountInSatoshi] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithDouble:(double)app.latestResponse.symbol_local.conversion]];
            
            app.localCurrencyFormatter.usesGroupingSeparator = NO;
            amountField.text = [app.localCurrencyFormatter stringFromNumber:number];
            app.localCurrencyFormatter.usesGroupingSeparator = YES;
        } @catch (NSException * e) {
            DLog(@"Exception: %@", e);
        }
    } else {
        @try {
            NSDecimalNumber *number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:amountInSatoshi] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:app.latestResponse.symbol_btc.conversion]];
            
            app.btcFormatter.usesGroupingSeparator = NO;
            amountField.text = [app.btcFormatter stringFromNumber:number];
            app.btcFormatter.usesGroupingSeparator = YES;
        } @catch (NSException * e) {
            DLog(@"Exception: %@", e);
        }
    }
    
    [self doCurrencyConversion];
}

- (void)doCurrencyConversion
{
    // If the amount entered exceeds amount available + fee, change the color of the amount text
    if (amountInSatoshi + [self getRecommendedFeeForAmount:amountInSatoshi] > availableAmount) {
        amountField.textColor = [UIColor redColor];
    }
    else {
        amountField.textColor = COLOR_BLOCKCHAIN_BLUE;
    }
    
    if (displayingLocalSymbol) {
        convertedAmountLabel.text = [app formatMoney:amountInSatoshi localCurrency:FALSE];
    } else {
        convertedAmountLabel.text = [app formatMoney:amountInSatoshi localCurrency:TRUE];
    }
}

- (uint64_t)getRecommendedFeeForAmount:(uint64_t)amount
{
    int64_t fee;
    if (self.sendFromAddress) {
        fee = [app.wallet recommendedTransactionFeeForAddress:self.fromAddress amount:amount];
    }
    else {
        fee = [app.wallet recommendedTransactionFeeForAccount:self.fromAccount amount:amount];
    }
    
    return fee;
}

- (void)setAmountFromUrlHandler:(NSString*)amountString withToAddress:(NSString*)addressString
{
    self.initialToAddressString = addressString;
    
    amountInSatoshi = [amountString doubleValue] * SATOSHI;
}

- (NSString *)labelForLegacyAddress:(NSString *)address
{
    if ([[app.wallet.addressBook objectForKey:address] length] > 0) {
        return [app.wallet.addressBook objectForKey:address];
        
    }
    else if ([app.wallet.allLegacyAddresses containsObject:address]) {
        NSString *label = [app.wallet labelForLegacyAddress:address];
        if (label && ![label isEqualToString:@""])
            return label;
    }
    
    return address;
}

- (void)dismissKeyboard
{
    [amountField resignFirstResponder];
    [toField resignFirstResponder];
    
    [self.view removeGestureRecognizer:self.tapGesture];
    self.tapGesture = nil;
}

#pragma mark - Textfield Delegates

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == selectAddressTextField) {
        [self selectFromAddressClicked:textField];
        return NO;  // Hide both keyboard and blinking cursor.
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.tapGesture == nil) {
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
        
        [self.view addGestureRecognizer:self.tapGesture];
    }
    
    // Move view content up when showing keyboard
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        CGRect frame = containerView.frame;
        frame.origin.y = 0;
        containerView.frame = frame;
    }];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    // Move view content back down when hiding keyboard
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        CGRect frame = containerView.frame;
        frame.origin.y = containerOffset;
        containerView.frame = frame;
    }];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == amountField) {
        
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray  *points = [newString componentsSeparatedByString:@"."];
        NSArray  *commas = [newString componentsSeparatedByString:@","];
        
        // Only one comma or point in input field allowed
        if ([points count] > 2 || [commas count] > 2)
            return NO;
        
        // Only 1 leading zero
        if (points.count == 1) {
            if (range.location == 1 && ![string isEqualToString:@"."] && [textField.text isEqualToString:@"0"]) {
                return NO;
            }
        }
        
        // When entering amount in BTC, max 8 decimal places
        if (!displayingLocalSymbol) {
            // Max number of decimal places depends on bitcoin unit
            NSUInteger maxlength = [@(SATOSHI) stringValue].length - [@(SATOSHI / app.latestResponse.symbol_btc.conversion) stringValue].length;
            
            if (points.count == 2) {
                NSString *decimalString = points[1];
                if (decimalString.length > maxlength) {
                    return NO;
                }
            }
            else if (commas.count == 2) {
                NSString *decimalString = commas[1];
                if (decimalString.length > maxlength) {
                    return NO;
                }
            }
        }
        
        // Fiat currencies have a max of 3 decimal places, most of them actually only 2. For now we will use 2.
        else {
            if (points.count == 2) {
                NSString *decimalString = points[1];
                if (decimalString.length > 2) {
                    return NO;
                }
            }
            else if (commas.count == 2) {
                NSString *decimalString = commas[1];
                if (decimalString.length > 2) {
                    return NO;
                }
            }
        }
        
        // Convert input amount to internal value
        NSString *amountString = [newString stringByReplacingOccurrencesOfString:@"," withString:@"."];
        if (displayingLocalSymbol) {
            amountInSatoshi = app.latestResponse.symbol_local.conversion * [amountString doubleValue];
        }
        else {
            amountInSatoshi = [app.wallet parseBitcoinValue:amountString];
        }
        
        [self performSelector:@selector(doCurrencyConversion) withObject:nil afterDelay:0.1f];
        
        return YES;
    } else if (textField == toField) {
        self.sendToAddress = true;
        self.toAddress = [textField.text stringByReplacingCharactersInRange:range withString:string];
        DLog(@"toAddress: %@", self.toAddress);
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

# pragma mark - AddressBook delegate

- (void)didSelectFromAddress:(NSString *)address
{
    self.sendFromAddress = true;
    
    NSString *addressOrLabel;
    NSString *label = [app.wallet labelForLegacyAddress:address];
    if (label && ![label isEqualToString:@""]) {
        addressOrLabel = label;
    }
    else {
        addressOrLabel = address;
    }
    
    availableAmount = [app.wallet getLegacyAddressBalance:address];
    
    selectAddressTextField.text = addressOrLabel;
    self.fromAddress = address;
    DLog(@"fromAddress: %@", address);
    
    [self doCurrencyConversion];
}

- (void)didSelectToAddress:(NSString *)address
{
    self.sendToAddress = true;
    
    toField.text = [self labelForLegacyAddress:address];
    self.toAddress = address;
    DLog(@"toAddress: %@", address);
}

- (void)didSelectFromAccount:(int)account
{
    self.sendFromAddress = false;
    
    availableAmount = [app.wallet getBalanceForAccount:account];
    
    selectAddressTextField.text = [app.wallet getLabelForAccount:account];
    self.fromAccount = account;
    DLog(@"fromAccount: %@", [app.wallet getLabelForAccount:account]);
    
    [self doCurrencyConversion];
}

- (void)didSelectToAccount:(int)account
{
    self.sendToAddress = false;
    
    toField.text = [app.wallet getLabelForAccount:account];
    self.toAccount = account;
    DLog(@"toAccount: %@", [app.wallet getLabelForAccount:account]);
}

#pragma mark - Actions

- (IBAction)selectFromAddressClicked:(id)sender
{
    [toField resignFirstResponder];
    [amountField resignFirstResponder];
    
#ifdef DISABLE_MULTIPLE_ACCOUNTS
    // If we only have one account and no legacy addresses -> can't change from address
    if ([app.wallet didUpgradeToHd] && ![app.wallet hasLegacyAddresses]) {
        return;
    }
#endif
    
    BCAddressSelectionView *addressSelectionView = [[BCAddressSelectionView alloc] initWithWallet:app.wallet showOwnAddresses:YES];
    addressSelectionView.delegate = self;
    
    [app showModalWithContent:addressSelectionView closeType:ModalCloseTypeBack showHeader:YES headerText:BC_STRING_SEND_FROM onDismiss:nil onResume:nil];
}

- (IBAction)addressBookClicked:(id)sender
{
    [toField resignFirstResponder];
    [amountField resignFirstResponder];
    
    BCAddressSelectionView *addressSelectionView = [[BCAddressSelectionView alloc] initWithWallet:app.wallet showOwnAddresses:NO];
    addressSelectionView.delegate = self;
    
    [app showModalWithContent:addressSelectionView closeType:ModalCloseTypeBack showHeader:YES headerText:BC_STRING_SEND_TO onDismiss:nil onResume:nil];
}

- (BOOL)startReadingQRCode
{
    NSError *error;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        // This should never happen - all devices we support (iOS 7+) have cameras
        DLog(@"QR code scanner problem: %@", [error localizedDescription]);
        return NO;
    }
    
    captureSession = [[AVCaptureSession alloc] init];
    [captureSession addInput:input];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + DEFAULT_FOOTER_HEIGHT);
    
    [videoPreviewLayer setFrame:frame];
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    [view.layer addSublayer:videoPreviewLayer];
    
    [app showModalWithContent:view closeType:ModalCloseTypeClose headerText:BC_STRING_SCAN_QR_CODE onDismiss:nil onResume:nil];
    
    [captureSession startRunning];
    
    return YES;
}

- (void)stopReadingQRCode
{
    [captureSession stopRunning];
    captureSession = nil;
    
    [videoPreviewLayer removeFromSuperlayer];
    
    [app closeModalWithTransition:kCATransitionFade];
    
    // Go to the send scren if we are not already on it
    [app showSendCoins];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects firstObject];
        
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            [self performSelectorOnMainThread:@selector(stopReadingQRCode) withObject:nil waitUntilDone:NO];
            
            // do something useful with results
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSDictionary *dict = [app parseURI:[metadataObj stringValue]];
                
                toField.text = [self labelForLegacyAddress:[dict objectForKey:@"address"]];
                self.toAddress = [dict objectForKey:@"address"];
                self.sendToAddress = true;
                DLog(@"toAddress: %@", self.toAddress);
                
                NSString *amountString = [dict objectForKey:@"amount"];
                if (app.latestResponse.symbol_btc) {
                    amountInSatoshi = ([amountString doubleValue] * SATOSHI);
                }
                else {
                    amountInSatoshi = 0.0;
                }
                
                // If the amount is empty, open the amount field
                if (amountInSatoshi == 0) {
                    amountField.text = nil;
                    [amountField becomeFirstResponder];
                }
                
                [self updateAmountField];
            });
        }
    }
}

- (IBAction)QRCodebuttonClicked:(id)sender
{
    [self startReadingQRCode];
}

- (IBAction)closeKeyboardClicked:(id)sender
{
    [amountField resignFirstResponder];
}

- (IBAction)labelAddressClicked:(id)sender
{
    [app.wallet addToAddressBook:toField.text label:labelAddressTextField.text];
    
    [app closeModalWithTransition:kCATransitionFade];
    labelAddressTextField.text = @"";
    
    // Complete payment
    [self confirmPayment];
}

- (IBAction)useAllClicked:(id)sender
{
    if (availableAmount == 0 || availableAmount < [self getRecommendedFeeForAmount:availableAmount]) {
        return;
    }
    
    uint64_t availableWithoutFee = availableAmount - [self getRecommendedFeeForAmount:availableAmount];
    amountInSatoshi = availableWithoutFee;
    
    [self updateAmountField];
}

- (IBAction)btcCodeClicked:(id)sender
{
    [app toggleSymbol];
}

- (IBAction)sendPaymentClicked:(id)sender
{
    // If user pasted an address into the toField, assign it to toAddress
    if ([self.toAddress length] == 0) {
        self.toAddress = toField.text;
        DLog(@"toAddress: %@", self.toAddress);
    }
    
    if ([self.toAddress length] == 0) {
        [app standardNotify:BC_STRING_YOU_MUST_ENTER_DESTINATION_ADDRESS];
        return;
    }
    
    if (self.sendToAddress && ![app.wallet isValidAddress:self.toAddress]) {
        [app standardNotify:BC_STRING_INVALID_TO_BITCOIN_ADDRESS];
        return;
    }
    
    if (!self.sendFromAddress && !self.sendToAddress && self.fromAccount == self.toAccount) {
        [app standardNotify:BC_STRING_FROM_TO_ACCOUNT_DIFFERENT];
        return;
    }
    
    if (self.sendFromAddress && self.sendToAddress && [self.fromAddress isEqualToString:self.toAddress]) {
        [app standardNotify:BC_STRING_FROM_TO_ADDRESS_DIFFERENT];
        return;
    }
    
    uint64_t value = amountInSatoshi;
    NSString *amountString = [amountField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
    if (value <= 0 || [amountString doubleValue] <= 0) {
        [app standardNotify:BC_STRING_INVALID_SEND_VALUE];
        return;
    }
    
    [self confirmPayment];

//    if ([[app.wallet.addressBook objectForKey:self.toAddress] length] == 0 && ![app.wallet.allLegacyAddresses containsObject:self.toAddress]) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BC_STRING_ADD_TO_ADDRESS_BOOK
//                                                        message:[NSString stringWithFormat:BC_STRING_ASK_TO_ADD_TO_ADDRESS_BOOK, self.toAddress]
//                                                       delegate:nil
//                                              cancelButtonTitle:BC_STRING_NO
//                                              otherButtonTitles:BC_STRING_YES, nil];
//        
//        alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
//            // do nothing & proceed
//            if (buttonIndex == 0) {
//                [self confirmPayment];
//            }
//            // let user save address in addressbook
//            else if (buttonIndex == 1) {
//                labelAddressLabel.text = toField.text;
//                
//                [app showModal:labelAddressView isClosable:TRUE];
//                
//                [labelAddressTextField becomeFirstResponder];
//            }
//        };
//        
//        [alert show];
//    } else {
//        [self confirmPayment];
//    }
}

@end
