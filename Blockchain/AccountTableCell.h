//
//  AccountTableCell.h
//  Blockchain
//
//  Created by Mark Pfluger on 12/2/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AccountTableCell : UITableViewCell

@property int accountIdx;

@property (strong, atomic) UIImageView *iconImage;
@property (strong, atomic) UIButton *editButton;
@property (strong, atomic) UILabel *amountLabel;
@property (strong, atomic) UILabel *labelLabel;

- (IBAction)editButtonclicked:(id)sender;

@end
