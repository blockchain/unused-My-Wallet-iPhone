//
//  PairingCodeDelegate.m
//  Blockchain
//
//  Created by Ben Reeves on 22/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "PrivateKeyReader.h"
#import "AppDelegate.h"
#import "BCModalView.h"

@implementation PrivateKeyReader

-(void)readPrivateKey:(void (^)(NSString*))__success error:(void (^)(NSString*))__error
{
    self.success = __success;
    self.error = __error;
    
    self.readerView = [[ZBarReaderView alloc] init];
    
    self.readerView.frame = CGRectMake(0, 0, app.window.frame.size.width, app.window.frame.size.height - DEFAULT_HEADER_HEIGHT);
    
    // Reduce size of qr code to be scanned as part of view size
    // Normalized coordinates and x/y flipped
    self.readerView.scanCrop = CGRectMake(0.2, 0.15, 0.6, 0.7);
    
    [self.readerView setReaderDelegate:self];
    
    [self.readerView start];
    
    [app showModalWithContent:self.readerView closeType:ModalCloseTypeClose onDismiss:^() {
        [self.readerView stop];
        
        self.readerView = nil;
        
        if (self.error) {
            self.error(nil);
        }
    } onResume:nil];
}

- (void) readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
{
    
    // do something uselful with results
    for(ZBarSymbol *sym in syms) {
        
        if (self.success) {
            
            NSString * privateKeyString = sym.data;
            
            NSString * format = [app.wallet detectPrivateKeyFormat:privateKeyString];
            
            if (!app.wallet || [format length] > 0) {
                self.success(privateKeyString);
            
                [app closeModalWithTransition:kCATransitionFade];
            } else {
                [app standardNotify:BC_STRING_UNSUPPORTED_PRIVATE_KEY_FORMAT];
            }
            
            break;
        }
    }
}

@end
