//
//  NSDate+Extensions.h
//  StackOverflow
//
//  Created by Ben Reeves on 13/03/2010.
//  Copyright 2010 Ben Reeves. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDate (Extensions)

-(NSString*)dayMonthYearString;

//this date with time set as 24:00
-(NSDate*)midnight;

//this date with time set as 00:00
-(NSDate*)thisMorning;

//this date + 24hrs
-(NSDate*)nextDay;

//this date - 24hrs
-(NSDate*)prevDay; 

//One hour before
-(NSDate*)hourAgo;

//Two days ago
-(NSDate*)twoDaysAgo;

//Seven Days ago
-(NSDate*)sevenDaysAgo;

-(BOOL)isWeekend;

-(BOOL)isOnTheSameWeekAs:(NSDate*)date;

-(NSString*)dayMonthString;

//28 days ago
-(NSDate*)twentyEightDaysAgo;

-(NSDate*)twentyEightDaysLater;

-(NSDate*)tenYearsLater;

+(NSDate*)dateForRSSString:(NSString*)string;

+(NSString*)RSSStringForDate:(NSDate*)date;

-(NSString*)shortHandDate;

//Returns true if the dates provided are on the same day
-(BOOL)isOnTheSameDayAsDate:(NSDate*)date;

-(NSString*)shortHandDateWithTime;

-(NSString*)time;

-(NSString*)month;

-(NSString*)dayOfMonth;

-(int)dayOfMonthN;

-(int)hour;

-(NSString*)dayOfWeek;

+(NSDate*)dateFromMilliSecondString:(NSString*)string;

@end
