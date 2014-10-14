//
//  AddressBookView.m
//  Blockchain
//
//  Created by Ben Reeves on 17/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "AddressBookView.h"
#import "Wallet.h"
#import "AppDelegate.h"
#import "ReceiveTableCell.h"
#import "SendViewController.h"

#define ROW_HEIGHT 68

@implementation AddressBookView

@synthesize addresses;
@synthesize labels;
@synthesize wallet;
@synthesize delegate;

bool showOwnAddresses;

- (id)initWithWallet:(Wallet*)_wallet showOwnAddresses:(BOOL)_showOwnAddresses
{
    if ([super initWithFrame:CGRectZero]) {
        
        self.wallet = _wallet;
        showOwnAddresses = _showOwnAddresses;
        
        addresses = [NSMutableArray array];
        labels = [NSMutableArray array];
        
        if (_showOwnAddresses) {
            addresses = [NSMutableArray arrayWithArray:_wallet.activeAddresses];
            
            for (NSString *addr in addresses) {
                [labels addObject:[_wallet labelForAddress:addr]];
            }
        }
        else {
            for (NSString * addr in [_wallet.addressBook allKeys]) {
                [addresses addObject:addr];
            }
            
            for (NSString *addr in addresses) {
                [labels addObject:[app.sendViewController labelForAddress:addr]];
            }
        }
        
        [[NSBundle mainBundle] loadNibNamed:@"AddressBookView" owner:self options:nil];
        
        [self addSubview:view];
        
        view.frame = CGRectMake(0, 0, app.window.frame.size.width, app.window.frame.size.height);
        
        // Hacky way to make sure the table view doesn't show empty entries (with divider lines)
        float tableHeight = ROW_HEIGHT * self.addresses.count;
        float tableSpace = view.frame.size.height - DEFAULT_HEADER_HEIGHT - 49;
        
        if (tableHeight < tableSpace) {
            CGRect frame = tableView.frame;
            frame.size.height = ROW_HEIGHT * self.addresses.count;
            tableView.frame = frame;
        }
    }
    return self;
}

- (void)setHeader:(NSString *)headerText
{
    headerLabel.text = headerText;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (showOwnAddresses) {
        [delegate didSelectFromAddress:[addresses objectAtIndex:[indexPath row]]];
    }
    else {
        [delegate didSelectToAddress:[addresses objectAtIndex:[indexPath row]]];
    }
    
    [app closeModalWithTransition:kCATransitionFromLeft];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [addresses count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ROW_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *addr = [addresses objectAtIndex:[indexPath row]];
    
    ReceiveTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"receive"];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ReceiveCell" owner:nil options:nil] objectAtIndex:0];
        
        // Don't show the watch only tag and resize the label and balance labels to use up the freed up space
        cell.labelLabel.frame = CGRectMake(20, 11, 185, 21);
        cell.balanceLabel.frame = CGRectMake(217, 11, 120, 21);
        
        [cell.watchLabel setHidden:TRUE];
    }
    
    NSString *label = [labels objectAtIndex:[indexPath row]];
    
    if (label)
        cell.labelLabel.text = label;
    else
        cell.labelLabel.text = BC_STRING_NO_LABEL;
    
    cell.addressLabel.text = addr;
    
    if (showOwnAddresses) {
        uint64_t balance = [app.wallet getAddressBalance:addr];
        cell.balanceLabel.text = [app formatMoney:balance];
    }
    else {
        cell.balanceLabel.text = nil;
    }
    
    // Selected cell color
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width,cell.frame.size.height)];
    [v setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
    [cell setSelectedBackgroundView:v];
    
    return cell;
}

@end
