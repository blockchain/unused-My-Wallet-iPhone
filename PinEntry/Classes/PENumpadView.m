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

#import "PENumpadView.h"

static CGRect Buttons[12];
#ifdef PINENTRY_KEYBOARD_SENDS_NOTIFICATIONS
NSString *kPinEntryKeyboardEvent = @"kPinEntryKeyboardEvent";
NSString *kPinEntryKeyboardCode = @"kPinEntryKeyboardCode";
#endif

@implementation PENumpadView

@synthesize delegate;

+ (void)initialize
{
	if(Buttons[0].size.height == 0) {
		Buttons[0]  = CGRectMake(0, 1, 105, 53);
		Buttons[1]  = CGRectMake(106, 1, 108, 53);
		Buttons[2]  = CGRectMake(215, 1, 105, 53);
		
		Buttons[3]  = CGRectMake(0, 55, 105, 53);
		Buttons[4]  = CGRectMake(106, 55, 108, 53);
		Buttons[5]  = CGRectMake(215, 55, 105, 53);
		
		Buttons[6]  = CGRectMake(0, 109, 105, 53);
		Buttons[7]  = CGRectMake(106, 109, 108, 53);
		Buttons[8]  = CGRectMake(215, 109, 105, 53);
		
		Buttons[9]  = CGRectMake(0, 163, 105, 53);
		Buttons[10] = CGRectMake(106, 163, 108, 53);
		Buttons[11] = CGRectMake(215, 163, 105, 53);
	};
}

- (id)init
{
	return [self initWithFrame:CGRectMake(0, 460-216, 320, 216)];
}

- (id)initWithFrame:(CGRect)frame
{
	if( (self = [super initWithFrame:frame]) ) {
		activeClip = -1;
		self.detailButon = PEKeyboardDetailNone;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if( (self = [super initWithCoder:aDecoder]) ) {
		activeClip = -1;
		self.detailButon = PEKeyboardDetailNone;
	}
	return self;
}

- (void)drawRect:(CGRect)rect
{
	[[UIImage imageNamed:[NSString stringWithFormat:@"PEKeyboard-1%@.png", detail]] drawAtPoint:CGPointMake(0, 0)];
	if(activeClip >= 0) {
		[[UIBezierPath bezierPathWithRect:Buttons[activeClip]] addClip];
		[[UIImage imageNamed:[NSString stringWithFormat:@"PEKeyboard-2%@.png", detail]] drawAtPoint:CGPointMake(0, 0)];
	}
}

- (void)dealloc
{
	[super dealloc];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *t = [touches anyObject];
	CGPoint p = [t locationInView:self];
	for(int i=0; i<12; ++i) {
		if(CGRectContainsPoint(Buttons[i], p)) {
			activeClip = i;
			[self setNeedsDisplay];
			break;
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	activeClip = -1;
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if(activeClip >= 0) {
		switch(activeClip) {
			case 9:
				activeClip = -1;
				if([detail isEqualToString: @""]) {
					[self touchesCancelled:touches withEvent:event];
					return;
				}
				[delegate keyboardViewDidOptKey];
				break;
			case 10:
				activeClip = 0;
				[delegate keyboardViewDidEnteredNumber:activeClip];
				break;
			case 11:
				activeClip = -2;
				[delegate keyboardViewDidBackspaced];
				break;
			default:
				activeClip++;
				[delegate keyboardViewDidEnteredNumber:activeClip];
		}
#ifdef PINENTRY_KEYBOARD_SENDS_NOTIFICATIONS
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:kPinEntryKeyboardEvent object:self 
		 userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:activeClip] forKey:kPinEntryKeyboardCode]];
#endif
	}
	[self touchesCancelled:touches withEvent:event];
}

- (void)setDetailButon:(NSUInteger)i
{
	switch (i) {
		case PEKeyboardDetailNone:
			detail = @"";
			break;
		case PEKeyboardDetailDone:
			detail = @"-done";
			break;
		case PEKeyboardDetailNext:
			detail = @"-next";
			break;
		case PEKeyboardDetailDot:
			detail = @"-dot";
			break;
		case PEKeyboardDetailEdit:
			detail = @"-edit";
			break;
	}
	[self setNeedsDisplay];
}

- (NSUInteger)detailButon
{
	return 0;
}

@end
