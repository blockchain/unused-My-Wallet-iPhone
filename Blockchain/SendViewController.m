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
BOOL isReadingQRCode;

float containerOffset;

uint64_t originalBtcAmount = 0.0;
BOOL didChangeDollarAmount = NO;

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
        selectAddressTextField.text = [app.wallet getLabelForAccount:defaultAccountIndex];
        self.fromAccount = defaultAccountIndex;
    }
    else {
        // Default setting: send from any address
        self.sendFromAddress = true;
        selectAddressTextField.text = BC_STRING_ANY_ADDRESS;
    }

    self.sendToAddress = true;
    
    amountKeyboardAccessoryView.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
    amountKeyboardAccessoryView.layer.borderColor = [[UIColor colorWithRed:181.0f/255.0f green:185.0f/255.0f blue:189.0f/255.0f alpha:1.0f] CGColor];
    
    amountField.inputAccessoryView = amountKeyboardAccessoryView;
    
    [toField setReturnKeyType:UIReturnKeyDone];
    
    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width,
                                 app.window.frame.size.height - DEFAULT_HEADER_HEIGHT - DEFAULT_FOOTER_HEIGHT);
    
    [self reloadWithCurrencyChange:NO];
}

- (void)reloadWithCurrencyChange:(BOOL)currencyChange
{
    // Populate address field from URL handler if available.
    if (self.initialToAddressString && toField != nil) {
        self.sendToAddress = true;
        self.toAddress = self.initialToAddressString;
        DLog(@"toAddress: %@", self.toAddress);
        
        toField.text = [self labelForLegacyAddress:self.toAddress];
        self.initialToAddressString = nil;
    }
    
    // Populate amount field from URL handler if available
    if (self.initialToAmountDouble > 0 && amountField != nil && app.latestResponse.symbol_btc) {
        
        double amountInSymbolBTC = (self.initialToAmountDouble / (double)app.latestResponse.symbol_btc.conversion);
        
        app.btcFormatter.usesGroupingSeparator = NO;
        amountField.text = [app.btcFormatter stringFromNumber:[NSNumber numberWithDouble:amountInSymbolBTC]];
        app.btcFormatter.usesGroupingSeparator = YES;
        
        originalBtcAmount = amountInSymbolBTC;
        didChangeDollarAmount = NO;
        
        self.initialToAmountDouble = 0;
    }
    
    if (app->symbolLocal && app.latestResponse.symbol_local && app.latestResponse.symbol_local.conversion > 0) {
        [btcCodeButton setTitle:app.latestResponse.symbol_local.code forState:UIControlStateNormal];
        displayingLocalSymbol = TRUE;
    } else if (app.latestResponse.symbol_btc) {
        [btcCodeButton setTitle:app.latestResponse.symbol_btc.symbol forState:UIControlStateNormal];
        displayingLocalSymbol = FALSE;
    }
    
    // Convert the amount field when the local currency changes
    uint64_t amount = SATOSHI;
    if ([amountField.text length] > 0) {
        NSString *amountString = [amountField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
        
        // If we are switching currency display, get the amount with the other currency
        if (currencyChange) {
            if (!displayingLocalSymbol) {
                // Restore original BTC amount instead of using conversion from fiat if there is an original amount
                if (!didChangeDollarAmount && originalBtcAmount != 0.0) {
                    amount = originalBtcAmount;
                }
                else {
                    amount = app.latestResponse.symbol_local.conversion * [amountString doubleValue];
                }
            } else {
                amount = [app.wallet parseBitcoinValue:amountString];
            }
        }
        else {
            if (displayingLocalSymbol) {
                amount =  app.latestResponse.symbol_local.conversion * [amountString doubleValue];
            } else {
                amount = [app.wallet parseBitcoinValue:amountString];
            }
        }
        
        if (displayingLocalSymbol) {
            @try {
                NSDecimalNumber *number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:amount] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithDouble:(double)app.latestResponse.symbol_local.conversion]];
                
                app.localCurrencyFormatter.usesGroupingSeparator = NO;
                amountField.text = [app.localCurrencyFormatter stringFromNumber:number];
                app.localCurrencyFormatter.usesGroupingSeparator = YES;
            } @catch (NSException * e) {
                DLog(@"Exception: %@", e);
            }
        } else {
            @try {
                NSDecimalNumber *number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:amount] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:app.latestResponse.symbol_btc.conversion]];
                
                app.btcFormatter.usesGroupingSeparator = NO;
                amountField.text = [app.btcFormatter stringFromNumber:number];
                app.btcFormatter.usesGroupingSeparator = YES;
            } @catch (NSException * e) {
                DLog(@"Exception: %@", e);
            }
        }
    }
    
    [self doCurrencyConversion];
}

- (void)reset
{
    [sendPaymentButton setEnabled:YES];
}

#pragma mark - Payment

- (void)reallyDoPayment
{
    transactionProgressListeners * listener = [[transactionProgressListeners alloc] init];
    
    listener.on_success = ^() {
        [app playBeepSound];
        
        [app standardNotify:BC_STRING_PAYMENT_SENT title:BC_STRING_SUCCESS delegate:nil];
        
        [sendPaymentButton setEnabled:TRUE];
        
        // Reset fields
        self.fromAddress = @"";
        if ([app.wallet didUpgradeToHd]) {
            // Default setting: send from default account
            self.sendFromAddress = false;
            int defaultAccountIndex = [app.wallet getDefaultAccountIndex];
            selectAddressTextField.text = [app.wallet getLabelForAccount:defaultAccountIndex];
            self.fromAccount = defaultAccountIndex;
        }
        else {
            // Default setting: send from any address
            self.sendFromAddress = true;
            selectAddressTextField.text = BC_STRING_ANY_ADDRESS;
        }
        self.sendToAddress = true;
        
        toField.text = @"";
        amountField.text = @"";
        self.fromAddress = @"";
        self.toAddress = @"";
        originalBtcAmount = 0.0;
        didChangeDollarAmount = NO;
        [self doCurrencyConversion];
        
        // Close transaction modal, go to transactions view, scroll to top and animate new transaction
        [app closeModalWithTransition:kCATransitionFade];
        [app.transactionsViewController animateNextCellAfterReload];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [app transactionsClicked:nil];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [app.transactionsViewController.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        });
    };
    
    listener.on_error = ^(NSString* error) {
        [app standardNotify:error];
        
        [sendPaymentButton setEnabled:TRUE];
        
        [app closeModalWithTransition:kCATransitionFade];
    };
    
    [sendPaymentButton setEnabled:FALSE];
    
    sendProgressModalText.text = BC_STRING_SENDING_TRANSACTION;
    
    [app showModalWithContent:sendProgressModal closeType:ModalCloseTypeNone headerText:BC_STRING_SENDING_TRANSACTION];
    
    uint64_t satoshiValue = [self getInputAmountInSatoshi];
    
    DLog(@"Sending uint64_t %llu Satoshi (String value: %@)", satoshiValue, [[NSNumber numberWithLongLong:satoshiValue] stringValue]);
    
    // Different ways of sending (from/to address or account
    if (self.sendFromAddress && self.sendToAddress) {
        DLog(@"From: %@", self.fromAddress);
        DLog(@"To: %@", self.toAddress);
        
        [app.wallet sendPaymentFromAddress:self.fromAddress toAddress:self.toAddress satoshiValue:[[NSNumber numberWithLongLong:satoshiValue] stringValue] listener:listener];
    }
    else if (self.sendFromAddress && !self.sendToAddress) {
        DLog(@"From: %@", self.fromAddress);
        DLog(@"To account: %d", self.toAccount);
        
        [app.wallet sendPaymentFromAddress:self.fromAddress toAccount:self.toAccount satoshiValue:[[NSNumber numberWithLongLong:satoshiValue] stringValue] listener:listener];
    }
    else if (!self.sendFromAddress && self.sendToAddress) {
        DLog(@"From account: %d", self.fromAccount);
        DLog(@"To: %@", self.toAddress);
        
        [app.wallet sendPaymentFromAccount:self.fromAccount toAddress:self.toAddress satoshiValue:[[NSNumber numberWithLongLong:satoshiValue] stringValue] listener:listener];
    }
    else if (!self.sendFromAddress && !self.sendToAddress) {
        DLog(@"From account: %d", self.fromAccount);
        DLog(@"To account: %d", self.toAccount);
        
        [app.wallet sendPaymentFromAccount:self.fromAccount toAccount:self.toAccount satoshiValue:[[NSNumber numberWithLongLong:satoshiValue] stringValue] listener:listener];
    }
}

- (uint64_t)getInputAmountInSatoshi
{
    NSString *amountString = [amountField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
    
    if (displayingLocalSymbol) {
        if (!didChangeDollarAmount && originalBtcAmount != 0.0) {
            return originalBtcAmount;
        }
        return app.latestResponse.symbol_local.conversion * [amountString doubleValue];
    } else {
        return [app.wallet parseBitcoinValue:amountString];
    }
}

- (void)confirmPayment
{
    NSString * amountBTCString   = [app formatMoney:[self getInputAmountInSatoshi] localCurrency:FALSE];
    NSString * amountLocalString = [app formatMoney:[self getInputAmountInSatoshi] localCurrency:TRUE];
    
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

- (void)doCurrencyConversion
{
    uint64_t amount = SATOSHI;
    
    if ([amountField.text length] > 0) {
        amount = [self getInputAmountInSatoshi];
    } else {
        amount = 0;
    }
    
    if (displayingLocalSymbol) {
        if (!didChangeDollarAmount && originalBtcAmount != 0.0) {
            amount = originalBtcAmount;
        }
        
        convertedAmountLabel.text = [app formatMoney:amount localCurrency:FALSE];
    } else {
        convertedAmountLabel.text = [app formatMoney:amount localCurrency:TRUE];
        originalBtcAmount = amount;
    }
}

- (void)setAmountFromUrlHandler:(NSString*)amountString withToAddress:(NSString*)addressString
{
    // Set toAddress
    //    self.toAddress = addressString;
    //    DLog(@"toAddress: %@", self.toAddress);
    self.initialToAddressString = addressString;
    
    // If we're in local currency, toggle to bitcoin since amount from URL is in BTC
    if (app->symbolLocal) {
        DLog(@"Toggling to BTC");
        [app toggleSymbol];
    }
    
    self.initialToAmountDouble = [amountString doubleValue] * SATOSHI;
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
    if (textField == amountField) {
        [self doCurrencyConversion];
    }
    
    if (self.tapGesture == nil) {
        self.tapGesture = [[UITapGestureRecognizer alloc]
                           initWithTarget:self
                           action:@selector(dismissKeyboard)];
        
        [self.view addGestureRecognizer:self.tapGesture];
    }
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        CGRect frame = containerView.frame;
        frame.origin.y = 0;
        containerView.frame = frame;
    }];
}

- (void) keyboardWillHide:(NSNotification *)note
{
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
        
        if ([points count] > 2 || [commas count] > 2)
            return NO;
        
        [self performSelector:@selector(doCurrencyConversion) withObject:nil afterDelay:0.1f];
        
        didChangeDollarAmount = displayingLocalSymbol;
        
        return YES;
    } else if (textField == toField) {
        self.sendToAddress = true;
        self.toAddress = [textField.text stringByReplacingCharactersInRange:range withString:string];
        DLog(@"toAddress: %@", self.toAddress);
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
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
        
    selectAddressTextField.text = addressOrLabel;
    self.fromAddress = address;
    DLog(@"fromAddress: %@", address);
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
    
    selectAddressTextField.text = [app.wallet getLabelForAccount:account];
    self.fromAccount = account;
    DLog(@"fromAccount: %@", [app.wallet getLabelForAccount:account]);
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

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            [self performSelectorOnMainThread:@selector(stopReadingQRCode) withObject:nil waitUntilDone:NO];
            isReadingQRCode = NO;
            
            // do something useful with results
            dispatch_sync(dispatch_get_main_queue(), ^{
                // Make sure we are displaying the BTC symbol
                // As amounts from uri's are in BTC
                BOOL toggledSymbolForURL = NO;
                if (app->symbolLocal) {
                    toggledSymbolForURL = YES;
                    [app toggleSymbol];
                }
                
                NSDictionary *dict = [app parseURI:[metadataObj stringValue]];
                
                toField.text = [self labelForLegacyAddress:[dict objectForKey:@"address"]];
                self.toAddress = [dict objectForKey:@"address"];
                self.sendToAddress = true;
                DLog(@"toAddress: %@", self.toAddress);
                
                NSString *amountString = [dict objectForKey:@"amount"];
                
                if (app.latestResponse.symbol_btc) {
                    double amountDouble = ([amountString doubleValue] * SATOSHI) / (double)app.latestResponse.symbol_btc.conversion;
                    
                    app.btcFormatter.usesGroupingSeparator = NO;
                    amountString = [app.btcFormatter stringFromNumber:[NSNumber numberWithDouble:amountDouble]];
                    app.btcFormatter.usesGroupingSeparator = YES;
                }
                
                // If the amount is empty, open the amount field
                if ([amountString isEqualToString:@"0"]) {
                    amountField.text = nil;
                    originalBtcAmount = 0.0;
                    didChangeDollarAmount = NO;
                    [amountField becomeFirstResponder];
                }
                // otherwise set the amountField to the amount from the URI
                else {
                    amountField.text = amountString;
                    originalBtcAmount = [app.wallet parseBitcoinValue:amountString];
                    didChangeDollarAmount = NO;
                }
                
                if (toggledSymbolForURL) {
                    [app toggleSymbol];
                }
                else {
                    [self doCurrencyConversion];
                }
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

- (IBAction)btcCodeClicked:(id)sender
{
    [app toggleSymbol];
}

- (IBAction)sendPaymentClicked:(id)sender
{
    // If user pasted an address into the toField, assign it to toAddress
    // TOOD not possible anymore?
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
    
    uint64_t value = [self getInputAmountInSatoshi];
    if (value <= 0) {
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
