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

#import <UIKit/UIKit.h>
#import "BCAddressSelectionView.h"
#import "BCAlertView.h"
#import <AVFoundation/AVFoundation.h>

@class Wallet;

@interface SendViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate, AddressSelectionDelegate> {
    IBOutlet UIView *containerView;
    
    IBOutlet UITextField *toFieldContainerField;
    IBOutlet UITextField *toField;
    IBOutlet UITextField *amountField;
    IBOutlet UILabel *convertedAmountLabel;
    
    IBOutlet UIView *amountKeyboardAccessoryView;
    
    IBOutlet UILabel *fromLabel;
    IBOutlet UITextField *selectAddressTextField;
    IBOutlet UIButton *addressBookButton;
    IBOutlet UIButton *sendPaymentButton;
    
    IBOutlet UIView *labelAddressView;
    IBOutlet UILabel *labelAddressLabel;
    IBOutlet UITextField *labelAddressTextField;
    
    IBOutlet UIView *sendProgressModal;
    IBOutlet UILabel *sendProgressModalText;
    IBOutlet UIActivityIndicatorView *sendProgressActivityIndicator;
    
    IBOutlet UIButton *btcCodeButton;

    BOOL displayingLocalSymbol;
}

@property(nonatomic, strong) NSString *initialToAddressString;

@property(nonatomic, strong) NSString *fromAddress;
@property(nonatomic, strong) NSString *toAddress;
@property int fromAccount;
@property int toAccount;
@property BOOL sendFromAddress;
@property BOOL sendToAddress;

@property(nonatomic, strong) UITapGestureRecognizer *tapGesture;

- (IBAction)selectFromAddressClicked:(id)sender;
- (IBAction)QRCodebuttonClicked:(id)sender;
- (IBAction)addressBookClicked:(id)sender;
- (IBAction)closeKeyboardClicked:(id)sender;

- (void)didSelectFromAddress:(NSString *)address;
- (void)didSelectToAddress:(NSString *)address;
- (void)didSelectFromAccount:(int)account;
- (void)didSelectToAccount:(int)account;

- (IBAction)sendPaymentClicked:(id)sender;
- (IBAction)labelAddressClicked:(id)sender;
- (IBAction)useAllClicked:(id)sender;

- (void)setAmountFromUrlHandler:(NSString*)amountString withToAddress:(NSString*)string;

- (NSString *)labelForLegacyAddress:(NSString *)address;

- (void)reload;

- (void)dismissKeyboard;

- (void)reset;

@end
