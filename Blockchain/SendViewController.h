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
#import "ZBarSDK.h"
#import "AddressBookView.h"
#import "BCAlertView.h"
#import "DropDownListView.h"

@class Wallet;

@interface SendViewController : UIViewController <ZBarReaderViewDelegate, AddressBookDelegate, kDropDownListViewDelegate> {
    IBOutlet UITextField * toFieldContainerField;
    IBOutlet UITextField * toField;
    IBOutlet UITextField * amountField;
   
    IBOutlet UIView * amountKeyboardAccessoryView;
    IBOutlet UILabel * currencyConversionLabel;

    
    IBOutlet UILabel *fromLabel;
    IBOutlet UIButton *selectAddressButton;
    IBOutlet UIButton *addressBookButton;
    IBOutlet UIButton * sendPaymentButton;
    IBOutlet UIView * labelAddressView;
    IBOutlet UILabel * labelAddressLabel;
    IBOutlet UITextField * labelAddressTextField;
    IBOutlet UIView * sendProgressModal;
    IBOutlet UILabel * sendProgressModalText;
    IBOutlet UIButton * btcCodeButton;
    DropDownListView * fromAddressDropDown;
    DropDownListView * addressBookdropDown;

    BOOL displayingLocalSymbol;
}

@property(nonatomic, strong) NSString *selectedAddress;
@property(nonatomic, strong) NSArray * addressBookAddress;
@property(nonatomic, strong) NSArray * fromAddresses;
@property(nonatomic, strong) ZBarReaderView * readerView;
@property(nonatomic, strong) NSString *toAddress;

- (IBAction)selectAddressClicked:(id)sender;
-(IBAction)QRCodebuttonClicked:(id)sender;
-(IBAction)addressBookClicked:(id)sender;
-(IBAction)btcCodeClicked:(id)sender;
-(IBAction)closeKeyboardClicked:(id)sender;

-(void)didSelectAddress:(NSString *)address;

-(IBAction)sendPaymentClicked:(id)sender;
-(IBAction)labelAddressClicked:(id)sender;

-(void)setToAddressFromUrlHandler:(NSString*)string;
-(void)setAmountFromUrlHandler:(NSString*)amountString;

-(void)reload;

@end
