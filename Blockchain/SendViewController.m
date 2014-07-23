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

@implementation SendViewController

-(void)dealloc {
    [btcCodeLabel release];
    [sendPaymentButton release];
    [amountKeyoboardAccessoryView release];
    [currencyConversionLabel release];
    [toField release];
    [fromField release];
    [labelAddressView release];
    [labelAddressLabel release];
    [labelAddressTextField release];
    [sendProgressModal release];
    [sendProgressModalText release];
    [toFieldContainerField release];
    
    self.readerView = nil;
    self.fromAddresses = nil;
    
    [super dealloc];
}

-(void)reload {
    self.fromAddresses = [app.wallet activeAddresses];
    
    [fromField reload];
    
    [fromField setIndex:0];
}

-(IBAction)labelAddressClicked:(id)sender {
    NSString * to = toField.text;
    
    [app.wallet addToAddressBook:to label:labelAddressTextField.text];
    
    [app closeModal];
        
    [self reallyDoPayment];
}

-(void)reallyDoPayment {
    uint64_t satoshiValue = [app.wallet parseBitcoinValue:amountField.text];
    
    NSString * to = toField.text;
    NSString * from = @"";
    if ([fromField index] > 0) {
        from = [self.fromAddresses objectAtIndex:[fromField index]-1];
    }
    
    transactionProgressListeners * listener = [[transactionProgressListeners alloc] init];
    
    [sendPaymentButton setEnabled:FALSE];
    
    listener.on_start = ^() {
        app.disableBusyView = TRUE;

        sendProgressModalText.text = @"Please Wait";
        
        [app showModal:sendProgressModal isClosable:TRUE onDismiss:^() {
            [app.wallet cancelTxSigning];
        } onResume:nil];
    };
    
    listener.on_begin_signing = ^() {
        sendProgressModalText.text = @"Signing Inputs";
    };
    
    listener.on_sign_progress = ^(int input) {
        sendProgressModalText.text = [NSString stringWithFormat:@"Signing Input %d", input];
    };
    
    listener.on_finish_signing = ^() {
        sendProgressModalText.text = @"Finished Signing Inputs";
    };
    
    listener.on_success = ^() {
        [app standardNotify:@"Payment Sent!" title:@"Success" delegate:nil];
        
        [sendPaymentButton setEnabled:TRUE];

        app.disableBusyView = FALSE;
        
        [app closeModal];
    };
    
    listener.on_error = ^(NSString* error) {
        [sendPaymentButton setEnabled:TRUE];

        app.disableBusyView = FALSE;

        [app closeModal];
    };
    
    [app.wallet sendPaymentTo:to from:from satoshiValue:[[NSNumber numberWithLongLong:satoshiValue] stringValue] listener:listener];
    
    [listener release];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {    
    NSString * to = toField.text;

    if (buttonIndex == 0) {
        [self reallyDoPayment];
    } else if (buttonIndex == 1) {
        labelAddressLabel.text = to;
        
        [app showModal:labelAddressView isClosable:TRUE];
        
        [labelAddressTextField becomeFirstResponder];
    }
}

-(IBAction)reviewPaymentClicked:(id)sender {
    NSString * to = toField.text;
    
    if ([to length] == 0) {
        [app standardNotify:@"You must enter a destination address"];
        return;
    }
    
    if (![app.wallet isValidAddress:to]) {
        [app standardNotify:@"Invalid to bitcoin address"];
        return;
    }
            
    uint64_t value = [app.wallet parseBitcoinValue:amountField.text];
    if (value <= 0) {
        [app standardNotify:@"Invalid Send Value"];
        return;
    }
    
    int countPriv = [[app.wallet activeAddresses] count];
    
    if (countPriv == 0) {
        [app standardNotify:@"You have no active bitcoin addresses available for sending"];
        return;
    }
    
    if ([[app.wallet.addressBook objectForKey:to] length] == 0 && ![app.wallet.allAddresses containsObject:to]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add to Address book?" 
                                                        message:[NSString stringWithFormat:@"Would you like to add the bitcoin address %@ to your address book?", to]
                                                       delegate:nil 
                                              cancelButtonTitle:@"No" 
                                              otherButtonTitles:@"Yes", nil];
        alert.delegate = self;
        
        [alert show];
        [alert release];
    } else {
        [self reallyDoPayment];
    }
}

-(void)doCurrencyConversion {
    uint64_t amount = SATOSHI;
    if ([amountField.text length] > 0)
        amount = [app.wallet parseBitcoinValue:amountField.text];
    
    currencyConversionLabel.text = [NSString stringWithFormat:@"%@ = %@", [app formatMoney:amount localCurrency:FALSE], [app formatMoney:amount localCurrency:TRUE]];

}
-(void)setToAddress:(NSString*)string {
    toField.text = string;
}

-(void)setAmount:(NSString*)amount {
    amountField.text = amount;
    
    [self doCurrencyConversion];
}

- (void) readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
{
    // do something useful with results
    for(ZBarSymbol *sym in syms) {
        
        NSDictionary * dict = [app parseURI:sym.data];
        toField.text = [dict objectForKey:@"address"];
        amountField.text = [dict objectForKey:@"amount"];
        
        [view stop];
        
        [app closeModal];

        break;
    }
    
    self.readerView = nil;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self doCurrencyConversion];
    
	[app.tabViewController responderMayHaveChanged];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self performSelector:@selector(doCurrencyConversion) withObject:nil afterDelay:0.1f];
    
    return TRUE;
}

- (BOOL)textFieldShouldReturn:(UITextField*)aTextField
{
    [aTextField resignFirstResponder];
    return YES;
}

-(void)initQRCodeView {
    self.readerView = [[ZBarReaderView new] autorelease];
    
    [self.readerView start];
    
    [self.readerView setReaderDelegate:self];
    
    [app showModal:self.readerView isClosable:TRUE onDismiss:^() {
        [self.readerView stop];
        
        self.readerView = nil;
    } onResume:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    if (app.latestResponse.symbol_btc)
        btcCodeLabel.text = app.latestResponse.symbol_btc.symbol;
    
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
    
    amountField.inputAccessoryView = amountKeyoboardAccessoryView;
    
    if (APP_IS_IPHONE5) {
        self.view.frame = CGRectMake(0, 0, 320, 450);
    }
    else {
        self.view.frame = CGRectMake(0, 0, 320, 361);
    }
    
    [self reload];
}

-(NSUInteger)countForValueField:(MultiValueField*)valueField {
    if (valueField == fromField) {
        return [self.fromAddresses count]+1;
    }
    return 0;
}

-(void)didSelectAddress:(NSString *)address {
    toField.text = address;
}

-(NSString*)titleForValueField:(MultiValueField*)valueField atIndex:(NSUInteger)index {
    if (valueField == fromField) {
        if (index == 0) {
            return @"Any Address";
        }
        
        NSString * address = [self.fromAddresses objectAtIndex:index-1];
        NSString * label = [app.wallet labelForAddress:address];
        if (label) {
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
    
    [addressBookView release];
}

-(IBAction)QRCodebuttonClicked:(id)sender {
    [self initQRCodeView];
}

@end
