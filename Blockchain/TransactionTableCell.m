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
#import "Output.h"
#import "Input.h"
#import "NSDate+Extensions.h"

@implementation TransactionTableCell

@synthesize transaction;

-(void)awakeFromNib {    
    labels = [[NSMutableArray alloc] initWithCapacity:5];
}


-(IBAction)transactionHashClicked:(UIButton *)button {
    [app pushWebViewController:[WebROOT stringByAppendingFormat:@"tx/%@", transaction->hash]];
}

-(void)reload {   
        
    float y = 36;
 
    if (transaction->time > 0)  {
        [hashButton setHidden:FALSE];
        [hashButton setTitle:[[NSDate dateWithTimeIntervalSince1970:transaction->time] shortHandDateWithTime] forState:UIControlStateNormal];
    } else {
        [hashButton setHidden:TRUE];
    }
    
    [btcButton setTitle:[app formatMoney:transaction->result] forState:UIControlStateNormal];
        
    for (UILabel * label in labels) {
        [label removeFromSuperview];
    }

    //Payment Received
    if (transaction->result >= 0) {
        
        if (transaction->result == 0) {
            [typeImageView setImage:[UIImage imageNamed:@"payment_moved.png"]];        
            [btcButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [btcButton setBackgroundImage:[UIImage imageNamed:@"button_grey.png"] forState:UIControlStateNormal];
        } else {
            [typeImageView setImage:[UIImage imageNamed:@"payment_received.png"]];
            [btcButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btcButton setBackgroundImage:[UIImage imageNamed:@"button_green.png"] forState:UIControlStateNormal];
        }
        
        NSArray * inputs = [transaction inputsNotFromWallet:app.wallet];
        
        if ([inputs count] == 0)
            inputs = transaction.inputs;
        
        
        //Show the inouts i.e. where the coins are from
        for (Input * input in inputs) {
            UILabel * label = [[[UILabel alloc] initWithFrame:CGRectMake(20, y, 286, 20)] autorelease];
            
            if (app.wallet)
                [label setText:[app.wallet labelForAddress:[[input prev_out] addr]]];
            else
                [label setText:[[input prev_out] addr]];

            [label setFont:[UIFont systemFontOfSize:12]];
            [label setTextColor:hashButton.titleLabel.textColor];
            
            [labels addObject:label];
            
            [self addSubview:label];
            
            y += 22;
        }
    } else if (transaction->result < 0) {
        
        
        [typeImageView setImage:[UIImage imageNamed:@"payment_sent.png"]];
        [btcButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btcButton setBackgroundImage:[UIImage imageNamed:@"button_red.png"] forState:UIControlStateNormal];
        
        NSArray * outputs = [transaction outputsNotToWallet:app.wallet];
        
        if ([outputs count] == 0)
            outputs = transaction.outputs;
        
        for (Output * output in outputs) {
            UILabel * label = [[[UILabel alloc] initWithFrame:CGRectMake(20, y, 286, 20)] autorelease];
            
            if (app.wallet)
                [label setText:[app.wallet labelForAddress:[output addr]]];
            else
                [label setText:[output addr]];

            [label setFont:[UIFont systemFontOfSize:12]];
            [label setTextColor:hashButton.titleLabel.textColor];
            
            [labels addObject:label];
            
            [self addSubview:label];
            
            y += 22;
        }
    }

    y += 5;
    
    [typeImageView sizeToFit];

    float x = typeImageView.frame.origin.x+typeImageView.frame.size.width+5;
    
    [hashButton setFrame:CGRectMake(x, hashButton.frame.origin.y, self.frame.size.width - x - 5, hashButton.frame.size.height)];

    
    [btcButton setFrame:CGRectMake(btcButton.frame.origin.x, y, btcButton.frame.size.width, btcButton.frame.size.height)];
    
    [confirmationsButton setFrame:CGRectMake(confirmationsButton.frame.origin.x, y, confirmationsButton.frame.size.width, confirmationsButton.frame.size.height)];

}

-(IBAction)btcbuttonclicked:(id)sender {
    [app toggleSymbol];
}

-(void)seLatestBlock:(LatestBlock*)block {
    
    int confirmations = block.height - transaction->block_height + 1;
    
    if (confirmations == 0 || transaction->block_height == 0) { 
        [confirmationsButton setHidden:FALSE];

        [confirmationsButton setBackgroundImage:[UIImage imageNamed:@"button_red.png"] forState:UIControlStateNormal];
        [confirmationsButton setTitle:[NSString stringWithFormat:@"Unconfirmed", confirmations] forState:UIControlStateNormal];
        
       
    } else if (confirmations < 100) { 
        [confirmationsButton setHidden:FALSE];

        [confirmationsButton setBackgroundImage:[UIImage imageNamed:@"button_blue.png"] forState:UIControlStateNormal];
        [confirmationsButton setTitle:[NSString stringWithFormat:@"%d Confirmations", confirmations] forState:UIControlStateNormal];
        
    } else {
        [confirmationsButton setHidden:YES];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)dealloc {
    [labels release];
    
    [typeImageView release];
    [confirmationsButton release];
    [hashButton release];
    [transaction release];
    [super dealloc];
}

@end
