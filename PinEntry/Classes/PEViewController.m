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

@property (nonatomic, readwrite, retain) NSString *pin;

@end


@implementation PEViewController

@synthesize pin, delegate;

- (void)viewDidLoad
{
	[super viewDidLoad];
	pins[0] = pin0;
	pins[1] = pin1;
	pins[2] = pin2;
	pins[3] = pin3;
	self.pin = @"";
}

- (void)dealloc
{
	self.pin = nil;
	[super dealloc];
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
		if([self.pin length] == 4)
			[delegate pinEntryControllerDidEnteredPin:self];
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
