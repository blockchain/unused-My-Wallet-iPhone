/********************************************************************************
*                                                                               *
* Copyright (c) 2010 Vladimir "Farcaller" Pouzanov <farcaller@gmail.com>        *
*                                                                               *
* Permission is hereby granted, free of charge, to any person obtaining a copy  *
* of this software and associated documentation files (the "Software"), to deal *
* in the Software without restriction, including without limitation the rights  *
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     *
* copies of the Software, and to permit persons to whom the Software is         *
* furnished to do so, subject to the following conditions:                      *
*                                                                               *
* The above copyright notice and this permission notice shall be included in    *
* all copies or substantial portions of the Software.                           *
*                                                                               *
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    *
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      *
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   *
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        *
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, *
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN     *
* THE SOFTWARE.                                                                 *
*                                                                               *
********************************************************************************/

#import "PEViewController.h"

@interface PEViewController ()

- (void)setPin:(int)pin enabled:(BOOL)yes;
- (void)redrawPins;

@property (nonatomic, readwrite, strong) NSString *pin;

@end


@implementation PEViewController

@synthesize pin, delegate;

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    // Move up pin entry views for bigger screens
    if ([[UIScreen mainScreen] bounds].size.height >= 568) {
        int moveUp = 60;
        
        CGRect frame = pin0.frame;
        frame.origin.y -= moveUp;
        pin0.frame = frame;
        
        frame = pin1.frame;
        frame.origin.y -= moveUp;
        pin1.frame = frame;
        
        frame = pin2.frame;
        frame.origin.y -= moveUp;
        pin2.frame = frame;
        
        frame = pin3.frame;
        frame.origin.y -= moveUp;
        pin3.frame = frame;
        
        frame = promptLabel.frame;
        frame.origin.y -= 48;
        promptLabel.frame = frame;
    }
    
    pins[0] = pin0;
	pins[1] = pin1;
	pins[2] = pin2;
	pins[3] = pin3;
	self.pin = @"";
}

- (IBAction)cancelChangePin:(id)sender
{
    [self.delegate cancelController];
}

- (void)setPin:(int)p enabled:(BOOL)yes
{
	pins[p].image = yes ? [UIImage imageNamed:@"PEPin-on.png"] : [UIImage imageNamed:@"PEPin-off.png"];
}

- (void)redrawPins
{
	for(int i=0; i<4; ++i) {
		[self setPin:i enabled:[self.pin length]>i];
	}
}

- (void)keyboardViewDidEnteredNumber:(int)num
{
	if([self.pin length] < 4) {
		self.pin = [NSString stringWithFormat:@"%@%d", self.pin, num];
		[self redrawPins];
        if([self.pin length] == 4) {
            // Short delay so the UI can update the PIN view before we go to the next page
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [delegate pinEntryControllerDidEnteredPin:self];
            });
        }
	}
}

- (void)keyboardViewDidBackspaced
{
	if([self.pin length] > 0) {
		self.pin = [self.pin substringToIndex:[self.pin length]-1];
		[self redrawPins];
		keyboard.detailButon = PEKeyboardDetailNone;
	}
}

- (void)keyboardViewDidOptKey
{
	[delegate pinEntryControllerDidEnteredPin:self];
}

- (void)setPrompt:(NSString *)p
{
	[self view];
	promptLabel.text = p;
}

- (NSString *)prompt
{
	return promptLabel.text;
}

- (void)resetPin
{
	self.pin = @"";
	keyboard.detailButon = PEKeyboardDetailNone;
	[self redrawPins];
}

@end
