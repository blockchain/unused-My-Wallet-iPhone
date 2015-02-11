//
//  ReceiveCoinsViewControllerViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 17/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "ReceiveCoinsViewController.h"
#import "AppDelegate.h"
#import "ReceiveTableCell.h"
#import "Address.h"
#import "PrivateKeyReader.h"
#import <Social/Social.h>
#import <Twitter/Twitter.h>

@implementation ReceiveCoinsViewController

@synthesize activeKeys;
@synthesize archivedKeys;

Boolean didClickAccount = NO;
int clickedAccount;

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width,
                                 app.window.frame.size.height - DEFAULT_HEADER_HEIGHT - DEFAULT_FOOTER_HEIGHT);
    
    // iPhone4/4S
    if ([[UIScreen mainScreen] bounds].size.height < 568) {
        int reduceImageSizeBy = 70;
        // Smaller QR Code Image
        qrCodeMainImageView.frame = CGRectMake(qrCodeMainImageView.frame.origin.x + reduceImageSizeBy/2, qrCodeMainImageView.frame.origin.y, qrCodeMainImageView.frame.size.width - reduceImageSizeBy, qrCodeMainImageView.frame.size.height - reduceImageSizeBy);
        
        // Move buttons up
        requestPaymentButton.frame = CGRectMake(requestPaymentButton.frame.origin.x, requestPaymentButton.frame.origin.y - reduceImageSizeBy, requestPaymentButton.frame.size.width, requestPaymentButton.frame.size.height);
        copyAddressButton.frame = CGRectMake(copyAddressButton.frame.origin.x, copyAddressButton.frame.origin.y - reduceImageSizeBy, copyAddressButton.frame.size.width, copyAddressButton.frame.size.height);
        labelAddressButton.frame = CGRectMake(requestPaymentButton.frame.origin.x, labelAddressButton.frame.origin.y - reduceImageSizeBy, labelAddressButton.frame.size.width, labelAddressButton.frame.size.height);
        archiveUnarchiveButton.frame = CGRectMake(archiveUnarchiveButton.frame.origin.x, archiveUnarchiveButton.frame.origin.y - reduceImageSizeBy, archiveUnarchiveButton.frame.size.width, archiveUnarchiveButton.frame.size.height);
    }
    
    [self reload];
}

- (void)reload
{
    self.activeKeys = [app.wallet activeLegacyAddresses];
    self.archivedKeys = [app.wallet archivedLegacyAddresses];
    
    if (app->symbolLocal && app.latestResponse.symbol_local && app.latestResponse.symbol_local.conversion > 0) {
        [btcCodeButton setTitle:app.latestResponse.symbol_local.code forState:UIControlStateNormal];
        displayingLocalSymbol = TRUE;
    } else if (app.latestResponse.symbol_btc) {
        [btcCodeButton setTitle:app.latestResponse.symbol_btc.symbol forState:UIControlStateNormal];
        displayingLocalSymbol = FALSE;
    }
    
    // Show table header with the QR code of an address from the default account
    // Image width is adjusted to screen size
    float imageWidth = ([[UIScreen mainScreen] bounds].size.height < 568) ? 140 : 210;
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, imageWidth + 42)];
    
    // Get an address: the first empty receive address for the default HD account
    // Or the first active legacy address if there are no HD accounts
    NSString *defaultAddress;
    
    if ([app.wallet getAccountsCount] > 0) {
        int defaultAccountIndex = [app.wallet getDefaultAccountIndex];
        defaultAddress = [app.wallet getReceiveAddressForAccount:defaultAccountIndex];
    }
    else if (activeKeys.count > 0) {
        for (NSString *address in activeKeys) {
            if (![app.wallet isWatchOnlyLegacyAddress:address]) {
                defaultAddress = address;
                break;
            }
        }
    }
    
    if ([app.wallet getAccountsCount] > 0 || activeKeys.count > 0) {
        // QR Code
        UIImageView *qrCodeImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - imageWidth)/2, 15, imageWidth, imageWidth)];
        qrCodeImageView.image = [self qrImageFromAddress:defaultAddress];
        qrCodeImageView.contentMode = UIViewContentModeScaleAspectFit;
        [headerView addSubview:qrCodeImageView];
        
        // Label of the default HD account
        UILabel *addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, imageWidth + 24, self.view.frame.size.width - 40, 18)];
        if ([app.wallet getAccountsCount] > 0) {
            int defaultAccountIndex = [app.wallet getDefaultAccountIndex];
            addressLabel.text = [app.wallet getLabelForAccount:defaultAccountIndex];
        }
        // Label of the default legacy address
        else {
            NSString *label = [app.wallet labelForLegacyAddress:defaultAddress];
            if (label.length > 0) {
                addressLabel.text = label;
            }
            else {
                addressLabel.text = defaultAddress;
            }
        }
        addressLabel.font = [UIFont systemFontOfSize:14];
        addressLabel.textAlignment = NSTextAlignmentCenter;
        addressLabel.textColor = [UIColor blackColor];
        [addressLabel setMinimumScaleFactor:.5f];
        [addressLabel setAdjustsFontSizeToFitWidth:YES];
        [headerView addSubview:addressLabel];
    }
    
    tableView.tableHeaderView = headerView;
    
    [tableView reloadData];
}

#pragma mark - Helpers

- (NSString *)getAddress:(NSIndexPath*)indexPath
{
    NSString *addr = nil;
    
    if ([indexPath section] == 1)
        addr = [activeKeys objectAtIndex:[indexPath row]];
    else if ([indexPath section] == 2)
        addr = [archivedKeys objectAtIndex:[indexPath row]];
    
    return addr;
}

- (NSString *)uriURL
{
    double amount = (double)[self getInputAmountInSatoshi] / SATOSHI;
    
    app.btcFormatter.usesGroupingSeparator = NO;
    NSString *amountString = [app.btcFormatter stringFromNumber:[NSNumber numberWithDouble:amount]];
    app.btcFormatter.usesGroupingSeparator = YES;
    
    amountString = [amountString stringByReplacingOccurrencesOfString:@"," withString:@"."];
    
    return [NSString stringWithFormat:@"bitcoin://%@?amount=%@", self.clickedAddress, amountString];
}

- (uint64_t)getInputAmountInSatoshi
{
    NSString *requestedAmountString = [requestAmountTextField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
    
    if (displayingLocalSymbol) {
        return app.latestResponse.symbol_local.conversion * [requestedAmountString doubleValue];
    } else {
        return [app.wallet parseBitcoinValue:requestedAmountString];
    }
}

- (void)doCurrencyConversion
{
    uint64_t amount = [self getInputAmountInSatoshi];
    
    if (displayingLocalSymbol) {
        currencyConversionLabel.text = [NSString stringWithFormat:@"%@ = %@", [app formatMoney:amount localCurrency:TRUE], [app formatMoney:amount localCurrency:FALSE]];
    } else {
        currencyConversionLabel.text = [NSString stringWithFormat:@"%@ = %@", [app formatMoney:amount localCurrency:FALSE], [app formatMoney:amount localCurrency:TRUE]];
    }
}

- (NSString *)getKey:(NSIndexPath*)indexPath
{
    NSString * key =  NULL;
    
    if ([indexPath section] == 0)
        key = [activeKeys objectAtIndex:[indexPath row]];
    else
        key = [archivedKeys objectAtIndex:[indexPath row]];
    
    return key;
}

- (UIImage *)qrImageFromAddress:(NSString *)address
{
    NSString *addressURL = [NSString stringWithFormat:@"bitcoin:%@", address];
    
    return [self createQRImageFromString:addressURL];
}

- (UIImage *)qrImageFromAddress:(NSString *)address amount:(double)amount
{
    app.btcFormatter.usesGroupingSeparator = NO;
    NSString *amountString = [app.btcFormatter stringFromNumber:[NSNumber numberWithDouble:amount]];
    app.btcFormatter.usesGroupingSeparator = YES;
    
    amountString = [amountString stringByReplacingOccurrencesOfString:@"," withString:@"."];
    
    NSString *addressURL = [NSString stringWithFormat:@"bitcoin:%@?amount=%@", address, amountString];
    
    return [self createQRImageFromString:addressURL];
}

- (UIImage *)createQRImageFromString:(NSString *)string
{
    return [self createNonInterpolatedUIImageFromCIImage:[self createQRFromString:string] withScale:10*[[UIScreen mainScreen] scale]];
}

- (CIImage *)createQRFromString:(NSString *)qrString
{
    // Need to convert the string to a UTF-8 encoded NSData object
    NSData *stringData = [qrString dataUsingEncoding:NSUTF8StringEncoding];
    
    // Create the filter
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // Set the message content and error-correction level
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"M" forKey:@"inputCorrectionLevel"];
    
    return qrFilter.outputImage;
}

- (UIImage *)createNonInterpolatedUIImageFromCIImage:(CIImage *)image withScale:(CGFloat)scale
{
    // Render the CIImage into a CGImage
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:image fromRect:image.extent];
    
    // Now we'll rescale using CoreGraphics
    UIGraphicsBeginImageContext(CGSizeMake(image.extent.size.width * scale, image.extent.size.width * scale));
    CGContextRef context = UIGraphicsGetCurrentContext();
    // We don't want to interpolate (since we've got a pixel-correct image)
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Tidy up
    UIGraphicsEndImageContext();
    CGImageRelease(cgImage);
    
    // Rotate the image
    UIImage *qrImage = [UIImage imageWithCGImage:[scaledImage CGImage]
                                           scale:[scaledImage scale]
                                     orientation:UIImageOrientationDownMirrored];
    
    return qrImage;
}

- (void)setQRPayment
{
    double amount = (double)[self getInputAmountInSatoshi] / SATOSHI;
    
    UIImage *image = [self qrImageFromAddress:self.clickedAddress amount:amount];
    
    qrCodePaymentImageView.image = image;
    qrCodePaymentImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self doCurrencyConversion];
}

# pragma mark - MFMailComposeViewControllerDelegate delegates

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result) {
        case MFMailComposeResultCancelled:
            break;
            
        case MFMailComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send email!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MFMailComposeResultSent:
            break;
            
        case MFMailComposeResultSaved:
            break;
            
        default:
            break;
    }
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark - MFMessageComposeViewControllerDelegate delegates

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MessageComposeResultSent:
            break;
            
        default:
            break;
    }
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Actions

- (IBAction)btcCodeClicked:(id)sender
{
    [app toggleSymbol];
    [self setQRPayment];
}

- (IBAction)scanKeyClicked:(id)sender
{
    PrivateKeyReader *reader = [[PrivateKeyReader alloc] initWithSuccess:^(NSString* privateKeyString) {
        [app.wallet addKey:privateKeyString];
    } error:nil];
    
    [app.slidingViewController presentViewController:reader animated:YES completion:nil];
}

- (IBAction)labelSaveClicked:(id)sender
{
    NSString *label = [labelTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSMutableCharacterSet *allowedCharSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [allowedCharSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
     
    if ([label rangeOfCharacterFromSet:[allowedCharSet invertedSet]].location != NSNotFound) {
        [app standardNotify:BC_STRING_LABEL_MUST_BE_ALPHANUMERIC];
        return;
    }
    
    NSString *addr = self.clickedAddress;
    
    [app.wallet setLabel:label forLegacyAddress:addr];
    
    [self reload];
    
    [app closeModalWithTransition:kCATransitionFade];
}

- (IBAction)copyAddressClicked:(id)sender
{
    NSString *addr = self.clickedAddress;
    
    UIView *lastButtonView = archiveUnarchiveButton;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 40)];
    [[lastButtonView superview] addSubview:label];
    
    label.textAlignment = NSTextAlignmentCenter;
    [label setFont:[UIFont systemFontOfSize:12.0f]];
    label.textColor = [UIColor darkGrayColor];
    label.numberOfLines = 2;
    label.minimumScaleFactor = .3f;
    label.adjustsFontSizeToFitWidth = YES;
    label.center = CGPointMake(lastButtonView.center.x, lastButtonView.center.y + 40);
    label.text = [NSString stringWithFormat:BC_STRING_COPIED_TO_CLIPBOARD, addr];
    
    label.alpha = 0;
    [UIView animateWithDuration:.1f animations:^{
        label.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:5.0f animations:^{
            label.alpha = 0;
        } completion:^(BOOL finished) {
            [label removeFromSuperview];
        }];
    }];
    
    [UIPasteboard generalPasteboard].string = addr;
}

- (IBAction)shareByTwitter:(id)sender
{
    SLComposeViewController *composeController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    
    [composeController setInitialText:[self formatPaymentRequest:@""]];
    [composeController addURL: [NSURL URLWithString:[self uriURL]]];
    
    [self presentViewController:composeController
                       animated:YES completion:nil];
    
    SLComposeViewControllerCompletionHandler myBlock = ^(SLComposeViewControllerResult result){
        if (result == SLComposeViewControllerResultCancelled) {
        } else {
        }
    };
    composeController.completionHandler = myBlock;
}

- (IBAction)shareByFacebook:(id)sender
{
    SLComposeViewController *composeController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    
    [composeController setInitialText:[self formatPaymentRequest:@""]];
    [composeController addURL: [NSURL URLWithString:[self uriURL]]];
    
    [self presentViewController:composeController animated:YES completion:nil];
    
    
    SLComposeViewControllerCompletionHandler myBlock = ^(SLComposeViewControllerResult result){
        if (result == SLComposeViewControllerResultCancelled) {
        } else {
        }
    };
    composeController.completionHandler = myBlock;
}

- (NSString*)formatPaymentRequest:(NSString*)url
{
    return [NSString stringWithFormat:BC_STRING_PAYMENT_REQUEST, url];
}

- (NSString*)formatPaymentRequestHTML:(NSString*)url
{
    return [NSString stringWithFormat:BC_STRING_PAYMENT_REQUEST_HTML, url];
}

- (IBAction)shareByMessageClicked:(id)sender
{
    if([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
        [messageController setMessageComposeDelegate:self];
        [messageController setSubject:BC_STRING_PAYMENT_REQUEST_TITLE];
        [messageController setBody:[self formatPaymentRequest:[self uriURL]]];
        [app.tabViewController presentViewController:messageController animated:YES completion:nil];
    }
    else {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:BC_STRING_ERROR message:BC_STRING_DEVICE_NO_SMS delegate:nil cancelButtonTitle:BC_STRING_OK otherButtonTitles:nil];
        [warningAlert show];
    }
}

- (IBAction)shareByEmailClicked:(id)sender
{
    if([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
        [mailController setMailComposeDelegate:self];
        NSData *jpegData = UIImageJPEGRepresentation(qrCodePaymentImageView.image, 1);
        [mailController addAttachmentData:jpegData mimeType:@"image/jpeg" fileName:@"QR code image"];
        [mailController setSubject:BC_STRING_PAYMENT_REQUEST_TITLE];
        [mailController setMessageBody:[self formatPaymentRequestHTML:[self uriURL]] isHTML:YES];
        [app.tabViewController presentViewController:mailController animated:YES completion:nil];
    }
    else {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:BC_STRING_ERROR message:BC_STRING_DEVICE_NO_EMAIL delegate:nil cancelButtonTitle:BC_STRING_OK otherButtonTitles:nil];
        [warningAlert show];
    }
}

- (IBAction)requestPaymentClicked:(id)sender
{
    [self setQRPayment];
    
    requestAmountTextField.inputAccessoryView = amountKeyoboardAccessoryView;
    amountKeyoboardAccessoryView.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
    amountKeyoboardAccessoryView.layer.borderColor = [[UIColor colorWithRed:181.0f/255.0f green:185.0f/255.0f blue:189.0f/255.0f alpha:1.0f] CGColor];
    
    // TODO i18n
    [app showModalWithContent:requestCoinsView closeType:ModalCloseTypeClose headerText:@"Request Payment" onDismiss:^() {
        self.clickedAddress = nil;
        requestAmountTextField.text = nil;
    } onResume:nil];
    
    [requestAmountTextField becomeFirstResponder];
}

- (IBAction)closeKeyboardClicked:(id)sender
{
    [requestAmountTextField resignFirstResponder];
}

- (IBAction)labelAddressClicked:(id)sender
{
    NSString *addr = self.clickedAddress;
    NSString *label = [app.wallet labelForLegacyAddress:addr];
    
    labelAddressLabel.text = addr;
    
    if (label && label.length > 0) {
        labelTextField.text = label;
    }
    
    // TODO i18n
    [app showModalWithContent:labelAddressView closeType:ModalCloseTypeClose headerText:@"Label Address" onDismiss:^() {
        self.clickedAddress = nil;
        labelTextField.text = nil;
    } onResume:nil];
    
    [labelTextField becomeFirstResponder];
}

- (IBAction)archiveAddressClicked:(id)sender
{
    NSString * addr = self.clickedAddress;
    NSInteger tag =  [app.wallet tagForLegacyAddress:addr];
    
    if (tag == 2) {
        [app.wallet unArchiveLegacyAddress:addr];
    }
    else {
        [app.wallet archiveLegacyAddress:addr];
    }
    
    [self reload];
    
    [app closeModalWithTransition:kCATransitionFade];
}


- (void)dismissKeyboard
{
    //[requestAmountTextField resignFirstResponder];
    [requestAmountTextField endEditing:YES];
    [app.modalView removeGestureRecognizer:self.tapGesture];
    self.tapGesture = nil;
}

# pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [app.tabViewController responderMayHaveChanged];
    self.tapGesture = [[UITapGestureRecognizer alloc]
                       initWithTarget:self
                       action:@selector(dismissKeyboard)];
    [app.modalView addGestureRecognizer:self.tapGesture];
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSArray  *points = [newString componentsSeparatedByString:@"."];
    NSArray  *commas = [newString componentsSeparatedByString:@","];
    
    if ([points count] > 2 || [commas count] > 2)
        return NO;
    
    [self performSelector:@selector(setQRPayment) withObject:nil afterDelay:0.1f];
    
    return YES;
}

#pragma mark - UITableview Delegates

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [archiveUnarchiveButton setHidden:(indexPath.section == 0)];
    [labelAddressButton setHidden:(indexPath.section == 0)];
    
    didClickAccount = (indexPath.section == 0);
    
    if (indexPath.section == 0) {
        int row = (int) indexPath.row;
        self.clickedAddress = [app.wallet getReceiveAddressForAccount:row];
        clickedAccount = row;
        
        optionsTitleLabel.text = [app.wallet getLabelForAccount:row];
    }
    else {
        NSString *addr = [self getAddress:[_tableView indexPathForSelectedRow]];
        NSInteger tag = [app.wallet tagForLegacyAddress:addr];
        NSString *label = [app.wallet labelForLegacyAddress:addr];
        
        self.clickedAddress = addr;
        
        if (tag == 2)
            [archiveUnarchiveButton setTitle:BC_STRING_UNARCHIVE forState:UIControlStateNormal];
        else
            [archiveUnarchiveButton setTitle:BC_STRING_ARCHIVE forState:UIControlStateNormal];
        
        // If there are no HD accounts, the last active address cannot be archived
        if ([app.wallet getAccountsCount] == 0 && self.activeKeys.count <= 1) {
            [archiveUnarchiveButton setTitleColor:COLOR_BUTTON_DARK_GRAY forState:UIControlStateNormal];
            [archiveUnarchiveButton setEnabled:NO];
        }
        else {
            [archiveUnarchiveButton setTitleColor:UIColorFromRGB(0x686868) forState:UIControlStateNormal];
            [archiveUnarchiveButton setEnabled:YES];
        }
        
        if (label.length > 0)
            optionsTitleLabel.text = label;
        else
            optionsTitleLabel.text = addr;
    }
    
    [app showModalWithContent:optionsModalView closeType:ModalCloseTypeClose headerText:optionsTitleLabel.text onDismiss:^() {
        // Slightly hacky - this assures that the view is removed and we this modal doesn't stick around and we can't show another one at the same time. Ideally we want to switch UIViewControllers or change showModalWithContent: to distinguish between hasCloseButton and hasBackButton
        [optionsModalView removeFromSuperview];
    } onResume:nil];
    
    // Put QR code in ImageView
    UIImage *image = [self qrImageFromAddress:self.clickedAddress];
    
    qrCodeMainImageView.image = image;
    qrCodeMainImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 44.0f;
    }
    
    return 70.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
    view.backgroundColor = COLOR_BACKGROUND_GRAY;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, self.view.frame.size.width, 14)];
    label.textColor = COLOR_FOREGROUND_GRAY;
    label.font = [UIFont systemFontOfSize:14.0];
    
    [view addSubview:label];
    
    NSString *labelString;
    
    if (section == 0)
        labelString = BC_STRING_MY_ACCOUNTS;
    else if (section == 1) {
        labelString = BC_STRING_IMPORTED_ADDRESSES;
        
        UIButton *addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        addButton.tintColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
        CGRect buttonFrame = addButton.frame;
        buttonFrame.origin.x = self.view.frame.size.width - buttonFrame.size.width - 20;
        buttonFrame.origin.y = 15;
        addButton.frame = buttonFrame;
        [addButton addTarget:self action:@selector(scanKeyClicked:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:addButton];
    }
    else if (section == 2)
        labelString = BC_STRING_IMPORTED_ADDRESSES_ARCHIVED;
    else
        @throw @"Unknown Section";
    
    label.text = [labelString uppercaseString];
    
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return [app.wallet getAccountsCount];
    else if (section == 1)
        return [activeKeys count];
    else
        return [archivedKeys count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    int n = 2;
    
    if ([archivedKeys count]) ++n;
    
    return n;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        int accountIndex = (int) indexPath.row;
        NSString *accountLabelString = [app.wallet getLabelForAccount:accountIndex];
        
        ReceiveTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"receiveAccount"];
        
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"ReceiveCell" owner:nil options:nil] objectAtIndex:0];
        
            // Don't show the watch only tag and resize the label and balance labels to use up the freed up space
            cell.labelLabel.frame = CGRectMake(20, 11, 185, 21);
            cell.balanceLabel.frame = CGRectMake(217, 11, 120, 21);
            [cell.watchLabel setHidden:TRUE];
        }
        
        cell.labelLabel.text = accountLabelString;
        cell.addressLabel.text = @"";
        
        uint64_t balance = [app.wallet getBalanceForAccount:accountIndex];
        
        // Selected cell color
        UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width,cell.frame.size.height)];
        [v setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
        [cell setSelectedBackgroundView:v];
        
        cell.balanceLabel.text = [app formatMoney:balance];
        
        return cell;
    }
    
    NSString *addr = [self getAddress:indexPath];
    
    Boolean isWatchOnlyLegacyAddress = [app.wallet isWatchOnlyLegacyAddress:addr];
    
    ReceiveTableCell *cell;
    if (isWatchOnlyLegacyAddress) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"receiveWatchOnly"];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"receiveNormal"];
    }
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ReceiveCell" owner:nil options:nil] objectAtIndex:0];
        
        if (isWatchOnlyLegacyAddress) {
            // Show the watch only tag and resize the label and balance labels so there is enough space
            cell.labelLabel.frame = CGRectMake(20, 11, 148, 21);
            
            cell.balanceLabel.frame = CGRectMake(254, 11, 83, 21);
            
            [cell.watchLabel setHidden:FALSE];
        }
        else {
            // Don't show the watch only tag and resize the label and balance labels to use up the freed up space
            cell.labelLabel.frame = CGRectMake(20, 11, 185, 21);
            
            cell.balanceLabel.frame = CGRectMake(217, 11, 120, 21);
            
            [cell.watchLabel setHidden:TRUE];
        }
    }
    
    NSString *label =  [app.wallet labelForLegacyAddress:addr];
    
    if (label)
        cell.labelLabel.text = label;
    else
        cell.labelLabel.text = BC_STRING_NO_LABEL;
    
    cell.addressLabel.text = addr;
    
    uint64_t balance = [app.wallet getLegacyAddressBalance:addr];
    
    // Selected cell color
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width,cell.frame.size.height)];
    [v setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
    [cell setSelectedBackgroundView:v];
    
    cell.balanceLabel.text = [app formatMoney:balance];
    
    return cell;
}

@end
