//
//  TransactionTableCell.m
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "TransactionTableCell.h"
#import "Transaction.h"
#import "AppDelegate.h"
#import "NSDate+Extensions.h"
#import "TransactionsViewController.h"

@implementation TransactionTableCell

@synthesize transaction;

- (void)awakeFromNib
{
    labels = [[NSMutableArray alloc] initWithCapacity:5];
}

- (void)reload
{
    if (transaction == NULL)
        return;
    
    float y = 30;
    
    if (transaction.time > 0)  {
        [dateButton setHidden:FALSE];
        [dateButton setTitle:[[NSDate dateWithTimeIntervalSince1970:transaction.time] shortHandDateWithTime] forState:UIControlStateNormal];
    } else {
        [dateButton setHidden:TRUE];
    }
    
    [btcButton setTitle:[app formatMoney:transaction.result] forState:UIControlStateNormal];
    [btcButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
    [btcButton.titleLabel setMinimumScaleFactor:.5f];
    
    for (UILabel * label in labels) {
        [label removeFromSuperview];
    }
    
    // Payment Received
    if (transaction.result >= 0) {
        NSString *labelString;
        
        if (transaction.intraWallet) {
            [transactionTypeLabel setText:BC_STRING_TRANSACTION_MOVED];
            [btcButton setBackgroundColor:COLOR_BUTTON_LIGHT_BLUE];
            
            labelString = @"You transferred bitcoin between accounts";
        } else {
            [transactionTypeLabel setText:@""];
            [btcButton setBackgroundColor:COLOR_BUTTON_GREEN];
            
            InOut *from = transaction.from;
            
            NSString *labelForAddressString = [app.wallet labelForLegacyAddress:from.externalAddresses.address];
            
            if (labelForAddressString && labelForAddressString.length > 0) {
                labelString = [NSString stringWithFormat:@"You received bitcoin from %@", labelForAddressString];
            }
            else {
                labelString = [NSString stringWithFormat:@"You received bitcoin from %@", @"a bitcoin address"];
            }
        }
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 280, 20)];
        [label setFont:[UIFont systemFontOfSize:13]];
        [label setTextColor:[UIColor darkGrayColor]];
        label.adjustsFontSizeToFitWidth = YES;
        
        [label setText:labelString];
        
        [labels addObject:label];
        [self addSubview:label];
        
        y += 22;
    }
    // Payment sent
    else if (transaction.result < 0) {
        NSString *labelString;
        
        if (transaction.intraWallet) {
            [transactionTypeLabel setText:BC_STRING_TRANSACTION_MOVED];
            [btcButton setBackgroundColor:COLOR_BUTTON_LIGHT_BLUE];
            
            labelString = @"You transferred bitcoin between accounts";
        } else {
            [transactionTypeLabel setText:@""];
            [btcButton setBackgroundColor:COLOR_BUTTON_RED];
            
            [transactionTypeLabel setText:@""];
            [btcButton setBackgroundColor:COLOR_BUTTON_GREEN];
            
            InOut *to = transaction.to;
            
            NSString *labelForAddressString = [app.wallet labelForLegacyAddress:to.externalAddresses.address];
            
            if (labelForAddressString && labelForAddressString.length > 0) {
                labelString = [NSString stringWithFormat:@"You sent bitcoin to %@", labelForAddressString];
            }
            else {
                labelString = [NSString stringWithFormat:@"You sent bitcoin to %@", @"a bitcoin address"];
            }
        }
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 280, 20)];
        [label setFont:[UIFont systemFontOfSize:13]];
        [label setTextColor:[UIColor darkGrayColor]];
        label.adjustsFontSizeToFitWidth = YES;
        
        [label setText:labelString];
        
        [labels addObject:label];
        [self addSubview:label];
        
        y += 22;
    }

    y += 5;

    // Make the transaction label minimal size to fit the text, then move it to it's position on the right and resize and move the date label to use up the rest of the space
    [transactionTypeLabel sizeToFit];
    float transactionTypeLabelX = self.frame.size.width - transactionTypeLabel.frame.size.width - 20;
    [transactionTypeLabel setFrame:CGRectMake(transactionTypeLabelX, transactionTypeLabel.frame.origin.y, transactionTypeLabel.frame.size.width, transactionTypeLabel.frame.size.height)];
    
    [dateButton setFrame:CGRectMake(20, dateButton.frame.origin.y, transactionTypeLabelX - 20 - 5, dateButton.frame.size.height)];
    
    // Move down the btc button and the confirmations label according to the number of inouts from above
    [btcButton setFrame:CGRectMake(btcButton.frame.origin.x, y, btcButton.frame.size.width, btcButton.frame.size.height)];
    
    [confirmationsLabel setFrame:CGRectMake(confirmationsLabel.frame.origin.x, y, confirmationsLabel.frame.size.width, confirmationsLabel.frame.size.height)];
}

- (void)seLatestBlock:(LatestBlock*)block
{
    // Hide confirmations if we're offline
    if (!block) {
        [confirmationsLabel setHidden:TRUE];
        return;
    }
    
    int confirmations = block.height - transaction.block_height + 1;
    
    if (confirmations <= 0 || transaction.block_height == 0) {
        [confirmationsLabel setHidden:FALSE];
        
        confirmationsLabel.textColor = [UIColor redColor];
        confirmationsLabel.text = BC_STRING_UNCONFIRMED;
    }
    else if (confirmations < 100) {
        [confirmationsLabel setHidden:FALSE];
        
        confirmationsLabel.textColor = [UIColor darkGrayColor];
        confirmationsLabel.text = [NSString stringWithFormat:BC_STRING_COUNT_CONFIRMATIONS, confirmations];
    }
    else {
        [confirmationsLabel setHidden:YES];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

#pragma mark button interactions

- (IBAction)transactionClicked:(UIButton *)button
{
    [app pushWebViewController:[WebROOT stringByAppendingFormat:@"tx/%@", transaction.myHash]];
}

- (IBAction)btcbuttonclicked:(id)sender
{
    [app toggleSymbol];
}

@end
