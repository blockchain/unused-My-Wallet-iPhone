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

@class Wallet;

@protocol AddressBookDelegate <NSObject>
- (void)didSelectFromAddress:(NSString*)address;
- (void)didSelectToAddress:(NSString*)address;
@end

@interface AddressBookView : UIView <UITableViewDelegate, UITableViewDataSource> {
    IBOutlet UILabel *headerLabel;
    IBOutlet UIView *view;
    IBOutlet UITableView *tableView;
}

- (id)initWithWallet:(Wallet*)_wallet showOwnAddresses:(BOOL)showOwnAddresses;
- (void)setHeader:(NSString *)headerText;

@property(nonatomic, strong) NSMutableArray *addresses;
@property(nonatomic, strong) NSMutableArray *labels;

@property(nonatomic, strong) Wallet *wallet;
@property(nonatomic, strong) id<AddressBookDelegate> delegate;

@end
