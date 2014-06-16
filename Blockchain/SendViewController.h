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
#import "MultiValueField.h"
#import "ZBarSDK.h"
#import "AddressBookView.h"

@class Wallet, MultiValueField;

@interface SendViewController : UIViewController <MultiValueFieldDataSource, ZBarReaderViewDelegate, AddressBookDelegate, UIAlertViewDelegate> {
    Wallet * wallet;
    IBOutlet MultiValueField * fromField;
    IBOutlet UITextField * toField;
    IBOutlet UITextField * amountField;
   
    IBOutlet UIView * amountKeyoboardAccessoryView;
    IBOutlet UILabel * currencyConversionLabel;

    IBOutlet UIView * labelAddressView;
    IBOutlet UILabel * labelAddressLabel;
    IBOutlet UITextField * labelAddressTextField;
}

@property(nonatomic, strong) Wallet * wallet;
@property(nonatomic, strong) NSMutableArray * fromAddress;
@property(nonatomic, strong) ZBarReaderView * readerView;

-(IBAction)QRCodebuttonClicked:(id)sender;
-(IBAction)addressBookClicked:(id)sender;

-(void)didSelectAddress:(NSString *)address;

-(IBAction)reviewPaymentClicked:(id)sender;
-(IBAction)labelAddressClicked:(id)sender;

-(void)setToAddress:(NSString*)string;
-(void)setAmount:(NSString*)amount;

-(void)didDismissModal;

@end
