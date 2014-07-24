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

#import "PEPinEntryController.h"

#define PS_VERIFY	0
#define PS_ENTER1	1
#define PS_ENTER2	2

static PEViewController *EnterController()
{
	PEViewController *c = [[PEViewController alloc] init];
	c.prompt = @"Please enter your pin";
	c.title = @"";
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSString *version = infoDictionary[@"CFBundleShortVersionString"];
    c.versionLabel.text = [NSString stringWithFormat:@"v%@", version];
    
	return c;
}

static PEViewController *NewController()
{
	PEViewController *c = [[PEViewController alloc] init];
	c.prompt = @"Please enter a new pin";
	c.title = @"";

    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSString *version = infoDictionary[@"CFBundleShortVersionString"];
    c.versionLabel.text = [NSString stringWithFormat:@"v%@", version];

    return c;
}

static PEViewController *VerifyController()
{
	PEViewController *c = [[PEViewController alloc] init];
	c.prompt = @"Confirm your pin";
	c.title = @"";

    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSString *version = infoDictionary[@"CFBundleShortVersionString"];
    c.versionLabel.text = [NSString stringWithFormat:@"v%@", version];

	return c;
}

@implementation PEPinEntryController

@synthesize pinDelegate, verifyOnly;

+ (PEPinEntryController *)pinVerifyController
{
	PEViewController *c = EnterController();
	PEPinEntryController *n = [[self alloc] initWithRootViewController:c];
	c.delegate = n;
	n->pinStage = PS_VERIFY;
	n->verifyOnly = YES;
	return [n autorelease];
}

+ (PEPinEntryController *)pinChangeController
{
	PEViewController *c = EnterController();
	PEPinEntryController *n = [[self alloc] initWithRootViewController:c];
	c.delegate = n;
	c.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:n action:@selector(cancelController)] autorelease];
	n->pinStage = PS_VERIFY;
	n->verifyOnly = NO;
	return [n autorelease];
}

+ (PEPinEntryController *)pinCreateController
{
	PEViewController *c = NewController();
	PEPinEntryController *n = [[self alloc] initWithRootViewController:c];
	c.delegate = n;
	n->pinStage = PS_ENTER1;
	n->verifyOnly = NO;
	return [n autorelease];
}

- (void)pinEntryControllerDidEnteredPin:(PEViewController *)controller
{
	switch (pinStage) {
		case PS_VERIFY:
			if(![self.pinDelegate pinEntryController:self shouldAcceptPin:[controller.pin intValue]]) {
				controller.prompt = @"Incorrect pin. Please retry.";
				[controller resetPin];
			} else {
				if(verifyOnly == NO) {
					PEViewController *c = NewController();
					c.delegate = self;
					pinStage = PS_ENTER1;
					[[self navigationController] pushViewController:c animated:YES];
					self.viewControllers = [NSArray arrayWithObject:c];
					[c release];
				}
			}
			break;
		case PS_ENTER1:
			pinEntry1 = [controller.pin intValue];
			PEViewController *c = VerifyController();
			c.delegate = self;
			[[self navigationController] pushViewController:c animated:YES];
			self.viewControllers = [NSArray arrayWithObject:c];
			pinStage = PS_ENTER2;
			[c autorelease];
			break;
		case PS_ENTER2:
			if([controller.pin intValue] != pinEntry1) {
				PEViewController *c = NewController();
				c.delegate = self;
				self.viewControllers = [NSArray arrayWithObjects:c, [self.viewControllers objectAtIndex:0], nil];
				[self popViewControllerAnimated:YES];
			} else {
				[self.pinDelegate pinEntryController:self changedPin:[controller.pin intValue]];
			}
			break;
		default:
			break;
	}
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
	pinStage = PS_ENTER1;
	return [super popViewControllerAnimated:animated];
}

- (void)cancelController
{
	[self.pinDelegate pinEntryControllerDidCancel:self];
}

@end
