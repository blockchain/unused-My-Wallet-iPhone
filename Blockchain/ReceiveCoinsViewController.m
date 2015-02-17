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

UIActionSheet *popupAccount;
UIActionSheet *popupAddressUnArchive;
UIActionSheet *popupAddressArchive;

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width,
                                 app.window.frame.size.height - DEFAULT_HEADER_HEIGHT - DEFAULT_FOOTER_HEIGHT);
    
    tableView.backgroundColor = [UIColor whiteColor];
    
    float imageWidth = 190;
    
    qrCodeMainImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - imageWidth) / 2, 25, imageWidth, imageWidth)];
    qrCodeMainImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    // iPhone4/4S
    if ([[UIScreen mainScreen] bounds].size.height < 568) {
        int reduceImageSizeBy = 43;

        // Smaller QR Code Image
        qrCodeMainImageView.frame = CGRectMake(qrCodeMainImageView.frame.origin.x + reduceImageSizeBy / 2,
                                               qrCodeMainImageView.frame.origin.y - 10,
                                               qrCodeMainImageView.frame.size.width - reduceImageSizeBy,
                                               qrCodeMainImageView.frame.size.height - reduceImageSizeBy);
        
        moreActionsButton.frame = CGRectMake(moreActionsButton.frame.origin.x,
                                             qrCodeMainImageView.frame.origin.y,
                                             moreActionsButton.frame.size.width,
                                             moreActionsButton.frame.size.height);
        
        
        // Move everything up on label view
        UIView *mainView = labelTextField.superview;
        
        for (UIView *view in mainView.subviews) {
            CGRect frame = view.frame;
            frame.origin.y -= 45;
            view.frame = frame;
        }
    }
    
    qrCodePaymentImageView.frame = CGRectMake(qrCodeMainImageView.frame.origin.x,
                                              qrCodeMainImageView.frame.origin.y,
                                              qrCodeMainImageView.frame.size.width,
                                              qrCodeMainImageView.frame.size.height);
    
    optionsTitleLabel.frame = CGRectMake(optionsTitleLabel.frame.origin.x,
                                         qrCodeMainImageView.frame.origin.y + qrCodeMainImageView.frame.size.height,
                                         optionsTitleLabel.frame.size.width,
                                         optionsTitleLabel.frame.size.height);
    
    popupAccount = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:BC_STRING_CANCEL destructiveButtonTitle:nil otherButtonTitles:
                    BC_STRING_SHARE_ON_TWITTER,
                    BC_STRING_SHARE_ON_FACEBOOK,
                    BC_STRING_SHARE_VIA_EMAIL,
                    BC_STRING_SHARE_VIA_SMS,
                    BC_STRING_COPY_ADDRESS,
                    nil];
    
    popupAddressArchive = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:BC_STRING_CANCEL destructiveButtonTitle:nil otherButtonTitles:
                           BC_STRING_SHARE_ON_TWITTER,
                           BC_STRING_SHARE_ON_FACEBOOK,
                           BC_STRING_SHARE_VIA_EMAIL,
                           BC_STRING_SHARE_VIA_SMS,
                           BC_STRING_COPY_ADDRESS,
                           BC_STRING_LABEL_ADDRESS,
                           BC_STRING_ARCHIVE_ADDRESS,
                           nil];
    
    popupAddressUnArchive = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:BC_STRING_CANCEL destructiveButtonTitle:nil otherButtonTitles:
                             BC_STRING_SHARE_ON_TWITTER,
                             BC_STRING_SHARE_ON_FACEBOOK,
                             BC_STRING_SHARE_VIA_EMAIL,
                             BC_STRING_SHARE_VIA_SMS,
                             BC_STRING_COPY_ADDRESS,
                             BC_STRING_LABEL_ADDRESS,
                             BC_STRING_UNARCHIVE_ADDRESS,
                             nil];
    
    [self reload];
}

- (void)reload
{
    self.activeKeys = [app.wallet activeLegacyAddresses];
    self.archivedKeys = [app.wallet archivedLegacyAddresses];
    
    // Reset the requested amount when showing the request screen
    requestAmountTextField.text = nil;
    
    if (app->symbolLocal && app.latestResponse.symbol_local && app.latestResponse.symbol_local.conversion > 0) {
        [btcButton setTitle:app.latestResponse.symbol_local.code forState:UIControlStateNormal];
        displayingLocalSymbol = TRUE;
    } else if (app.latestResponse.symbol_btc) {
        [btcButton setTitle:app.latestResponse.symbol_btc.symbol forState:UIControlStateNormal];
        displayingLocalSymbol = FALSE;
    }
    
    // Show table header with the QR code of an address from the default account
    float imageWidth = qrCodeMainImageView.frame.size.width;

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, imageWidth + 50)];
    
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

        qrCodeMainImageView.image = [self qrImageFromAddress:defaultAddress];

        [headerView addSubview:qrCodeMainImageView];
        
        // Label of the default HD account
        UILabel *addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, imageWidth + 30, self.view.frame.size.width - 40, 18)];
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
#warning this broken in locales that use , for .?
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
    
    [btcButton setTitle:[app formatMoney:amount localCurrency:FALSE] forState:UIControlStateNormal];
    [fiatButton setTitle:[app formatMoney:amount localCurrency:TRUE] forState:UIControlStateNormal];
    
    if (displayingLocalSymbol) {
        [btcButton setBackgroundColor:COLOR_BACKGROUND_GRAY];
        [fiatButton setBackgroundColor:[UIColor orangeColor]];
    } else {
        [btcButton setBackgroundColor:[UIColor orangeColor]];
        [fiatButton setBackgroundColor:COLOR_BACKGROUND_GRAY];
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

- (IBAction)moreActionsClicked:(id)sender
{
    if (didClickAccount) {
        [popupAccount showInView:[UIApplication sharedApplication].keyWindow];
    }
    else {
        if ([archivedKeys containsObject:self.clickedAddress]) {
            [popupAddressUnArchive showInView:[UIApplication sharedApplication].keyWindow];
        }
        else {
            [popupAddressArchive showInView:[UIApplication sharedApplication].keyWindow];
        }
    }
}

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
    [UIPasteboard generalPasteboard].string = addr;
    
//    UIView *lastButtonView = archiveUnarchiveButton;
//    
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 40)];
//    [[lastButtonView superview] addSubview:label];
//    
//    label.textAlignment = NSTextAlignmentCenter;
//    [label setFont:[UIFont systemFontOfSize:12.0f]];
//    label.textColor = [UIColor darkGrayColor];
//    label.numberOfLines = 2;
//    label.minimumScaleFactor = .3f;
//    label.adjustsFontSizeToFitWidth = YES;
//    label.center = CGPointMake(lastButtonView.center.x, lastButtonView.center.y + 40);
//    label.text = [NSString stringWithFormat:BC_STRING_COPIED_TO_CLIPBOARD, addr];
//    
//    label.alpha = 0;
//    [UIView animateWithDuration:.1f animations:^{
//        label.alpha = 1;
//    } completion:^(BOOL finished) {
//        [UIView animateWithDuration:5.0f animations:^{
//            label.alpha = 0;
//        } completion:^(BOOL finished) {
//            [label removeFromSuperview];
//        }];
//    }];
    
}

- (IBAction)shareByTwitter:(id)sender
{
    SLComposeViewController *composeController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    
    [composeController setInitialText:[self formatPaymentRequest:@""]];
    [composeController addURL: [NSURL URLWithString:[self uriURL]]];
    
    [self presentViewController:composeController animated:YES completion:nil];
    
    composeController.completionHandler = ^(SLComposeViewControllerResult result) {
        [self toggleKeyboard];
    };
}

- (IBAction)shareByFacebook:(id)sender
{
    SLComposeViewController *composeController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    
    [composeController setInitialText:[self formatPaymentRequest:@""]];
    [composeController addURL: [NSURL URLWithString:[self uriURL]]];
    
    [self presentViewController:composeController animated:YES completion:nil];
    
    composeController.completionHandler = ^(SLComposeViewControllerResult result) {
        [self toggleKeyboard];
    };
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

- (IBAction)labelAddressClicked:(id)sender
{
    NSString *addr = self.clickedAddress;
    NSString *label = [app.wallet labelForLegacyAddress:addr];
    
    labelAddressLabel.text = addr;
    
    if (label && label.length > 0) {
        labelTextField.text = label;
    }
    
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveButton.frame = CGRectMake(0, 0, self.view.frame.size.width, 46);
    saveButton.backgroundColor = COLOR_BUTTON_GRAY;
    [saveButton setTitle:BC_STRING_SAVE forState:UIControlStateNormal];
    [saveButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    saveButton.titleLabel.font = [UIFont systemFontOfSize:17.0];
    
    [saveButton addTarget:self action:@selector(labelSaveClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [labelTextField setReturnKeyType:UIReturnKeyDone];
    labelTextField.delegate = self;
    
    labelTextField.inputAccessoryView = saveButton;
    
    [app showModalWithContent:labelAddressView closeType:ModalCloseTypeClose headerText:BC_STRING_LABEL_ADDRESS onDismiss:^() {
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


- (void)toggleKeyboard
{
    if ([requestAmountTextField isFirstResponder]) {
        [requestAmountTextField resignFirstResponder];
    } else {
        [requestAmountTextField becomeFirstResponder];
    }
}

# pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (popup == popupAccount && buttonIndex > 4) {
        return;
    }
    
    switch (buttonIndex) {
        case 0:
            [self shareByTwitter:nil];
            break;
        case 1:
            [self shareByFacebook:nil];
            break;
        case 2:
            [self shareByEmailClicked:nil];
            break;
        case 3:
            [self shareByMessageClicked:nil];
            break;
        case 4:
            [self copyAddressClicked:nil];
            break;
        case 5:
            [self labelAddressClicked:nil];
            break;
        case 6:
            [self archiveAddressClicked:nil];
            break;
        default:
            break;
    }
}

# pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([[UIScreen mainScreen] bounds].size.height < 568) {
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleKeyboard)];
        [app.modalView addGestureRecognizer:self.tapGesture];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if (textField == labelTextField) {
        [self labelSaveClicked:nil];
        return YES;
    }
    
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
    didClickAccount = (indexPath.section == 0);
    
    if (indexPath.section == 0) {
        int row = (int) indexPath.row;
        self.clickedAddress = [app.wallet getReceiveAddressForAccount:row];
        clickedAccount = row;
        
        optionsTitleLabel.text = [app.wallet getLabelForAccount:row];
    }
    else {
        NSString *addr = [self getAddress:[_tableView indexPathForSelectedRow]];
        NSString *label = [app.wallet labelForLegacyAddress:addr];
        
        self.clickedAddress = addr;
        
        if (label.length > 0)
            optionsTitleLabel.text = label;
        else
            optionsTitleLabel.text = addr;
    }
    
    [app showModalWithContent:requestCoinsView closeType:ModalCloseTypeClose headerText:BC_STRING_REQUEST_AMOUNT onDismiss:^() {
        // Slightly hacky - this assures that the view is removed and we this modal doesn't stick around and we can't show another one at the same time. Ideally we want to switch UIViewControllers or change showModalWithContent: to distinguish between hasCloseButton and hasBackButton
        [requestCoinsView removeFromSuperview];
    } onResume:^() {
        // Reset the requested amount when showing the request screen
        requestAmountTextField.text = nil;
    }];
    
    [self setQRPayment];

    requestAmountTextField.inputAccessoryView = amountKeyoboardAccessoryView;
    amountKeyoboardAccessoryView.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
    amountKeyoboardAccessoryView.layer.borderColor = [[UIColor colorWithRed:181.0f/255.0f green:185.0f/255.0f blue:189.0f/255.0f alpha:1.0f] CGColor];

    requestAmountTextField.hidden = YES;
    [requestAmountTextField becomeFirstResponder];

    
    
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
    return 45.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 45)];
    view.backgroundColor = [UIColor whiteColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, self.view.frame.size.width, 14)];
    label.textColor = COLOR_FOREGROUND_GRAY;
    label.font = [UIFont systemFontOfSize:14.0];
    
    [view addSubview:label];
    
    NSString *labelString;
    
    if (section == 0)
        labelString = BC_STRING_MY_ACCOUNTS;
    else if (section == 1) {
        labelString = BC_STRING_IMPORTED_ADDRESSES;
        
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 20 - 20, 14, 25, 25)];
        [addButton setImage:[UIImage imageNamed:@"new-grey"] forState:UIControlStateNormal];
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
            cell.backgroundColor = COLOR_BACKGROUND_GRAY;
        
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
        cell.backgroundColor = COLOR_BACKGROUND_GRAY;
        
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
