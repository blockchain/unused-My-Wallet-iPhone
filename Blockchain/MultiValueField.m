//
//  MultiValueField.m
//  JCJJobSearch
//
//  Created by Ben Reeves on 28/03/2010.
//  Copyright 2010 Ben Reeves. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "MultiValueField.h"

@implementation MultiValueField

@synthesize source;
@synthesize index;
@synthesize valueColor;
@synthesize valueFont;
@synthesize currentLabel;
@synthesize valueAlignment;


-(void)selectFirstValueMatchingString:(NSString*)string {	
	for (int ii = 0; ii < [source countForValueField:self]; ++ii) {
		NSString *value = [source titleForValueField:self atIndex:ii];
		if ([value isEqualToString:string]) {
			[self selectIndex:ii animated:NO];
			return;
		}
	}
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    
	if (self = [super initWithCoder:aDecoder]) {
		valueAlignment = NSTextAlignmentCenter;
		valueFont = [UIFont systemFontOfSize:14.0f];
		valueColor = [UIColor blackColor];
	}
	return self;
}

-(void)drawRect:(CGRect)rect {
	[self reload];	
}

-(int)nfields {
	return nfields;
}

-(void)setCanvasNeedsDisplay {
	for (UIView * sview in self.subviews) {
		[sview setNeedsDisplay];
	}
}

-(void)reload {	    
    nfields = [source countForValueField:self];
    
    [self selectIndex:0 animated:FALSE];
}


-(void)setValueFont:(UIFont *)nvfont {
	valueFont = nvfont;
	
	[self setCanvasNeedsDisplay];
}

-(void)setValueColor:(UIColor *)nvcolor {
	valueColor = nvcolor;
	
	[self setCanvasNeedsDisplay];
}

-(NSString*)currentValue {
	return [source titleForValueField:self atIndex:index];
}

-(void)selectIndex:(int)findex animated:(BOOL)animated {
    int oldIndex = index;
    
	if (findex >= nfields)
		index = 0; //Wrap around when we reach the end
	else if (findex < 0)
		index = nfields-1; //Wrap around when we reach the end
    else
        index = findex;
    
    UILabel * new = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];

    new.adjustsFontSizeToFitWidth = YES;
    [new setMinimumScaleFactor:.5f];
    
    new.text = [source titleForValueField:self atIndex:index];
    
    new.font = valueFont;
    new.textColor = valueColor;
    new.textAlignment = valueAlignment;
    new.backgroundColor = [UIColor clearColor];
    new.opaque = FALSE;
    
    [currentLabel removeFromSuperview];

    [self addSubview:new];

    self.currentLabel = new;
    
    if (animated) {
        CATransition *animation = [CATransition animation]; 
        [animation setDuration:ANIMATION_DURATION]; 
        
        [animation setType:kCATransitionPush]; 
        
        if (oldIndex > index && index != 0)
            [animation setSubtype:kCATransitionFromRight];
        else
            [animation setSubtype:kCATransitionFromLeft];

        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        
        [currentLabel.layer addAnimation:animation forKey:@"ShowModal"]; 
    }
}

-(IBAction)nextValue:(id)sender {
	[self nextValue];
}

-(IBAction)previousValue:(id)sender {
	[self previousValue];
}

-(void)previousValue {
    [self selectIndex:index-1 animated:YES];
	
	if ([source respondsToSelector:@selector(valueFieldDidChange:)])
		[[self source] valueFieldDidChange:self];
}

-(void)nextValue {
	
	BOOL animated = YES;
	
    [self selectIndex:index+1 animated:animated];
    
	if ([source respondsToSelector:@selector(valueFieldDidChange:)])
		[[self source] valueFieldDidChange:self];
	
	lastValueChange = [[NSDate date] timeIntervalSince1970];
}

@end
