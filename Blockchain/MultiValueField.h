/*
 * 
 * Copyright (c) 2012, Ben Reeves. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */

#import <Foundation/Foundation.h>

@protocol MultiValueFieldDataSource;
@protocol MultiValueFieldDelegate;

@interface MultiValueField : UIView {
	UIColor * valueColor;
	UIFont * valueFont;
    UILabel * currentLabel;

	int index;
	id<MultiValueFieldDataSource> source;
	NSTextAlignment valueAlignment;
	int nfields;
	NSTimeInterval lastValueChange;
}

@property(nonatomic, strong) IBOutlet id<MultiValueFieldDataSource> source;
@property(nonatomic, assign) int index;
@property(nonatomic, strong) UIColor * valueColor;
@property(nonatomic, strong) UIFont * valueFont;
@property(nonatomic, assign) NSTextAlignment valueAlignment;
@property(nonatomic, strong) UILabel * currentLabel;

-(int)nfields;
-(NSString*)currentValue;
-(void)nextValue;
-(void)previousValue;

-(IBAction)nextValue:(id)sender;
-(IBAction)previousValue:(id)sender;

-(void)selectIndex:(int)findex animated:(BOOL)animated;
-(void)selectFirstValueMatchingString:(NSString*)string;
-(void)reload;

@end

@protocol MultiValueFieldDataSource <NSObject>
-(NSUInteger)countForValueField:(MultiValueField*)valueField;
-(NSString*)titleForValueField:(MultiValueField*)valueField atIndex:(NSUInteger)index;
@optional
-(void)valueFieldDidChange:(MultiValueField*)valueField;

@end


