//
//  ManualPairView.h
//  Blockchain
//
//  Created by Mark Pfluger on 9/25/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BCManualPairView : UIView {
    IBOutlet UITextField *walletIdentifierTextField;
}

@property (nonatomic, strong) IBOutlet UITextField *passwordTextField;

-(IBAction)didEndWalletIdentifier:(id)sender;
-(IBAction)didEndPassword:(id)sender;

-(IBAction)continueClicked:(id)sender;

@end
