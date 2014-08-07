//
//  PairingCodeDelegate.m
//  Blockchain
//
//  Created by Ben Reeves on 22/07/2014.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "PrivateKeyReader.h"
#import "AppDelegate.h"

@implementation PrivateKeyReader


-(void)readPrivateKey:(void (^)(NSString*))__success error:(void (^)(NSString*))__error {
    self.success = __success;
    self.error = __error;
    
    self.readerView = [[ZBarReaderView alloc] init];
    
    [app showModal:self.readerView isClosable:TRUE onDismiss:^() {
        [self.readerView stop];
        
        self.readerView = nil;
        
        if (self.error) {
            self.error(nil);
        }
    } onResume:nil];
    
    [self.readerView start];
    
    [self.readerView setReaderDelegate:self];
}

- (void) readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img {
    
    // do something uselful with results
    for(ZBarSymbol *sym in syms) {
        
        if (self.success) {
            
            NSString * privateKeyString = sym.data;
            
            NSString * format = [app.wallet detectPrivateKeyFormat:privateKeyString];
            
            if (!app.wallet || [format length] > 0) {
                self.success(privateKeyString);
            
                [app closeModal];
            } else {
                [app standardNotify:BC_UNSUPPORTED_PRIVATE_KEY_FORMAT];
            }
            
            break;
        }
    }
}

@end
