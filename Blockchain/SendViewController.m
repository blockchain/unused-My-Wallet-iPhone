//
//  SendViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 17/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "SendViewController.h"
#import "Wallet.h"
#import "MultiValueField.h"
#import "AppDelegate.h"
#import "ZBarSDK.h"
#import "AddressBookView.h"
#import "TabViewController.h"
#import "UncaughtExceptionHandler.h"
#import "UITextField+Blocks.h"
#import "UIAlertView+Blocks.h"

@implementation SendViewController

#pragma mark - Lifecycle

-(void)viewDidAppear:(BOOL)animated {
    sendProgressModalText.text = nil;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:LOADING_TEXT_NOTIFICAITON_KEY object:nil queue:nil usingBlock:^(NSNotification * notification) {
        
        sendProgressModalText.text = [notification object];
    }];
}

-(void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewDidLoad {
    [super viewDidLoad];

    [toFieldContainerField setShouldBegindEditingBlock:^BOOL(UITextField * field) {
        return FALSE;
    }];
    
    fromField.valueFont = [UIFont systemFontOfSize:14];
    fromField.valueColor = [UIColor darkGrayColor];

    amountKeyboardAccessoryView.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
    amountKeyboardAccessoryView.layer.borderColor = [[UIColor colorWithRed:181.0f/255.0f green:185.0f/255.0f blue:189.0f/255.0f alpha:1.0f] CGColor];
    
    amountField.inputAccessoryView = amountKeyboardAccessoryView;
    
    [toField setReturnKeyType:UIReturnKeyDone];
    
    if (APP_IS_IPHONE5) {
        self.view.frame = CGRectMake(0, 0, 320, 450);
    }
    else {
        self.view.frame = CGRectMake(0, 0, 320, 361);
    }
    
    [self reload];
}

-(void)reload {
    self.fromAddresses = [app.wallet activeAddresses];
    
    [fromField reload];
    
    [fromField setIndex:0];
    
    if (app->symbolLocal && app.latestResponse.symbol_local && app.latestResponse.symbol_local.conversion > 0) {
        [btcCodeButton setTitle:app.latestResponse.symbol_local.code forState:UIControlStateNormal];
        displayingLocalSymbol = TRUE;
    } else if (app.latestResponse.symbol_btc) {
        [btcCodeButton setTitle:app.latestResponse.symbol_btc.symbol forState:UIControlStateNormal];
        displayingLocalSymbol = FALSE;
    }
    
    [self doCurrencyConversion];
}

#pragma mark - Payment

-(void)reallyDoPayment {
    uint64_t satoshiValue = [self getInputAmountInSatoshi];
    
    NSString * to = self.toAddress;
    NSString * from = @"";
    if ([fromField index] > 0) {
        from = [self.fromAddresses objectAtIndex:[fromField index]-1];
    }
    
    transactionProgressListeners * listener = [[transactionProgressListeners alloc] init];
    
    [sendPaymentButton setEnabled:FALSE];
    
    listener.on_start = ^() {
        app.disableBusyView = TRUE;

        sendProgressModalText.text = BC_PLEASE_WAIT;
        
        [app showModal:sendProgressModal isClosable:FALSE onDismiss:^() {
            [app.wallet cancelTxSigning];
        } onResume:nil];
    };
    
    listener.on_begin_signing = ^() {
        sendProgressModalText.text = BC_SIGNING_INPUTS;
    };
    
    listener.on_sign_progress = ^(int input) {
        sendProgressModalText.text = [NSString stringWithFormat:BC_SIGNING_INPUT, input];
    };
    
    listener.on_finish_signing = ^() {
        sendProgressModalText.text = BC_FINISHED_SIGNING_INPUTS;
    };
    
    listener.on_success = ^() {
        [app standardNotify:BC_PAYMENT_SENT title:BC_SUCCESS delegate:nil];
        
        [sendPaymentButton setEnabled:TRUE];

        app.disableBusyView = FALSE;
        
        // Clear fields
        toField.text = @"";
        amountField.text = @"";
        
        [app closeModal];
    };
    
    listener.on_error = ^(NSString* error) {
        [sendPaymentButton setEnabled:TRUE];

        app.disableBusyView = FALSE;

        [app closeModal];
    };
    
    [app.wallet sendPaymentTo:to from:from satoshiValue:[[NSNumber numberWithLongLong:satoshiValue] stringValue] listener:listener];
}


-(uint64_t)getInputAmountInSatoshi {
    if (displayingLocalSymbol) {
        return app.latestResponse.symbol_local.conversion * [amountField.text doubleValue];
    } else {
        return [app.wallet parseBitcoinValue:amountField.text];
    }
}

- (void)confirmPayment {
    
    NSString * amountBTCString   = [app formatMoney:[self getInputAmountInSatoshi] localCurrency:FALSE];
    NSString * amountLocalString = [app formatMoney:[self getInputAmountInSatoshi] localCurrency:TRUE];

    NSMutableString *messageString = [NSMutableString stringWithFormat:BC_CONFIRM_PAYMENT_OF, amountBTCString, amountLocalString, self.toAddress];
    
    if (![toField.text isEqualToString:self.toAddress]) {
        [messageString appendFormat:@" (%@)", toField.text];
    }
    
    
    BCAlertView *alert = [[BCAlertView alloc] initWithTitle:BC_CONFIRM_PAYMENT
                                                    message:messageString
                                                   delegate:self
                                          cancelButtonTitle:BC_NO
                                          otherButtonTitles:BC_YES, nil];
    
    alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            [self reallyDoPayment];
        }
    };
    
    [alert show];
}

#pragma mark - UI Helpers

-(void)doCurrencyConversion {
    uint64_t amount = SATOSHI;

    if ([amountField.text length] > 0) {
        amount = [self getInputAmountInSatoshi];
    } else if (displayingLocalSymbol) {
        amount = app.latestResponse.symbol_local.conversion;
    }
    if (displayingLocalSymbol) {
        currencyConversionLabel.text = [NSString stringWithFormat:@"%@ = %@", [app formatMoney:amount localCurrency:TRUE], [app formatMoney:amount localCurrency:FALSE]];
    } else {
        currencyConversionLabel.text = [NSString stringWithFormat:@"%@ = %@", [app formatMoney:amount localCurrency:FALSE], [app formatMoney:amount localCurrency:TRUE]];
    }
}

-(void)setToAddressFromUrlHandler:(NSString*)string {
    self.toAddress = string;
    toField.text = [self labelForAddress:self.toAddress];
}

-(void)setAmountFromUrlHandler:(NSString*)amountString {
    
    double amountDouble = 0.0;
    double displayValue = 0.0;

    if (app->symbolLocal) {
        [app toggleSymbol];
    }

    // get decimal bitcoin value
    if (app.latestResponse.symbol_btc) {
        displayValue = ([amountString doubleValue] * SATOSHI) / (double)app.latestResponse.symbol_btc.conversion;
    } else {
        displayValue = amountDouble;
    }
    
    amountString = [app.btcFormatter stringFromNumber:[NSNumber numberWithDouble:displayValue]];
    amountField.text = amountString;

    [self doCurrencyConversion];
}

- (NSString *)labelForAddress:(NSString *)address {

    if ([[app.wallet.addressBook objectForKey:address] length] > 0) {
        return [app.wallet.addressBook objectForKey:address];
    
    }
    else if ([app.wallet.allAddresses containsObject:address]) {
        NSString *label = [app.wallet labelForAddress:address];
        if (label && ![label isEqualToString:@""])
            return label;
    }

    return address;

}

- (void) readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
{
    // do something useful with results
    for(ZBarSymbol *sym in syms) {
        
        //Make sure we are displaying the BTC symbol
        //As amounts from uri's are in BTC
        if (app->symbolLocal) {
            [app toggleSymbol];
        }
        
        NSDictionary * dict = [app parseURI:sym.data];
        
        toField.text = [self labelForAddress:[dict objectForKey:@"address"]];
        self.toAddress = [dict objectForKey:@"address"];
        
        NSString *amountString = [dict objectForKey:@"amount"];
        
        if (app.latestResponse.symbol_btc) {
            double amountDouble = ([amountString doubleValue] * SATOSHI) / (double)app.latestResponse.symbol_btc.conversion;
            
            amountString = [app.btcFormatter stringFromNumber:[NSNumber numberWithDouble:amountDouble]];
        }
        
        amountField.text = amountString;
        
        [view stop];
        
        [app closeModal];

        break;
    }
    
    self.readerView = nil;
}

#pragma mark - Textfield Delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    if (textField == amountField) {
        [self doCurrencyConversion];
    }
    
    [app.tabViewController responderMayHaveChanged];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == amountField) {
        [self performSelector:@selector(doCurrencyConversion) withObject:nil afterDelay:0.1f];
    }
    
    return TRUE;
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
    return YES;
}

# pragma mark- Addres book delegate
-(void)didSelectAddress:(NSString *)address {
    toField.text = [self labelForAddress:address];
    self.toAddress = address;
}

-(NSUInteger)countForValueField:(MultiValueField*)valueField {
    if (valueField == fromField) {
        return [self.fromAddresses count]+1;
    }
    return 0;
}

-(NSString*)titleForValueField:(MultiValueField*)valueField atIndex:(NSUInteger)index {
    if (valueField == fromField) {
        if (index == 0) {
            return @"Any Address";
        }
        
        NSString * address = [self.fromAddresses objectAtIndex:index-1];

        NSString * label = [app.wallet labelForAddress:address];
        if (label && ![label isEqualToString:@""]) {
            return label;
        } else {
            return address;
        }
    }
    
    return @"";
}

#pragma mark - Actions
-(IBAction)addressBookClicked:(id)sender {
    AddressBookView *addressBookView = [[AddressBookView alloc] initWithWallet:app.wallet];
    addressBookView.delegate = self;

    [app showModal:addressBookView isClosable:TRUE onDismiss:^() {
        [self.readerView stop];
        
        self.readerView = nil;
        
        [app.wallet cancelTxSigning];
    } onResume:nil];
}

-(IBAction)QRCodebuttonClicked:(id)sender {
    self.readerView = [[ZBarReaderView alloc] init];
    
    [self.readerView start];
    
    [self.readerView setReaderDelegate:self];
    
    [app showModal:self.readerView isClosable:TRUE onDismiss:^() {
        [self.readerView stop];
        
        self.readerView = nil;
    } onResume:nil];
}

-(IBAction)closeKeyboardClicked:(id)sender
{
    [amountField resignFirstResponder];
}

-(IBAction)labelAddressClicked:(id)sender {
    [app.wallet addToAddressBook:toField.text label:labelAddressTextField.text];
    
    [app closeModal];
    labelAddressTextField.text = @"";
    
    // Complete payment
    [self confirmPayment];
}


-(IBAction)btcCodeClicked:(id)sender {
    [app toggleSymbol];
}

-(IBAction)sendPaymentClicked:(id)sender {
    
    // If user pasted an address into the toField, assign it to toAddress
    if ([self.toAddress length] == 0)
        self.toAddress = toField.text;
    
    if ([self.toAddress length] == 0) {
        [app standardNotify:BC_YOU_MUST_ENTER_DESTINATION_ADDRESS];
        return;
    }
    
    if (![app.wallet isValidAddress:self.toAddress]) {
        [app standardNotify:BC_INVALID_TO_BITCOIN_ADDRESS];
        return;
    }
    
    uint64_t value = [self getInputAmountInSatoshi];
    if (value <= 0) {
        [app standardNotify:BC_INVALID_SEND_VALUE];
        return;
    }
    
    int countPriv = [[app.wallet activeAddresses] count];
    
    if (countPriv == 0) {
        [app standardNotify:BC_NO_ACTIVE_BITCOIN_ADDRESSES_AVAILABLE];
        return;
    }
    
    if ([[app.wallet.addressBook objectForKey:self.toAddress] length] == 0 && ![app.wallet.allAddresses containsObject:self.toAddress]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BC_ADD_TO_ADDRESS_BOOK
                                                        message:[NSString stringWithFormat:BC_ASK_TO_ADD_TO_ADDRESS_BOOK, self.toAddress]
                                                       delegate:nil
                                              cancelButtonTitle:BC_NO
                                              otherButtonTitles:BC_YES, nil];
        
        alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
            // do nothing & proceed
            if (buttonIndex == 0) {
                [self confirmPayment];
            }
            // let user save address in addressbook
            else if (buttonIndex == 1) {
                labelAddressLabel.text = toField.text;
                
                [app showModal:labelAddressView isClosable:TRUE];
                
                [labelAddressTextField becomeFirstResponder];
            }
        };
        
        [alert show];
    } else {
        [self confirmPayment];
    }
}


@end
