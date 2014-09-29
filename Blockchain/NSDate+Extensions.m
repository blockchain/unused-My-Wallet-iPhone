//
//  NSDate+Extensions.m
//  StackOverflow
//
//  Created by Ben Reeves on 13/03/2010.
//  Copyright 2010 Ben Reeves. All rights reserved.
//

#import "NSDate+Extensions.h"

#define SECSINADAY 86400
#define SECSINANHOUR 3600
#define SECSINANWEEK 604800
#define SECSIN28DAYS 2419200

NSDateFormatter * rssDateFormatter = nil;
NSDateFormatter * dayMonthYearFormatter = nil;
NSDateFormatter * dayMonthFormatter = nil;
NSDateFormatter * shortHandDateFormatter = nil;
NSDateFormatter * dayOfWeekFormatter = nil;
NSDateFormatter * dayOfMonthFormatter = nil;
NSDateFormatter * monthFormatter = nil;
NSDateFormatter * timeFormatter = nil;
NSDateFormatter * shortHandDateFormatterWithTime = nil;
NSDateFormatter * shortHandDateFormatterWithTimeCurrentYear = nil;

@implementation NSDate (Extensions)


-(NSString*)shortHandDateWithTime {
	if (shortHandDateFormatterWithTime == nil) {
		shortHandDateFormatterWithTime = [[NSDateFormatter alloc] init];
		[shortHandDateFormatterWithTime setDateFormat:@"EE d MMMM yyyy @ hh:mm aa"];
	}
    
    if (shortHandDateFormatterWithTimeCurrentYear == nil) {
        shortHandDateFormatterWithTimeCurrentYear = [[NSDateFormatter alloc] init];
        [shortHandDateFormatterWithTimeCurrentYear setDateFormat:@"EE d MMMM @ hh:mm aa"];
    }
    
    // Include the year only if if the date is not in the current year
    NSDateComponents *components1 = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit) fromDate:[NSDate date]];
    NSDateComponents *components2 = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit) fromDate:self];
    
    if ([components1 year] == [components2 year]) {
        	return [shortHandDateFormatterWithTimeCurrentYear stringFromDate:self];
    }
    
	return [shortHandDateFormatterWithTime stringFromDate:self];
}

-(NSString*)time {
	if (timeFormatter == nil) {
		timeFormatter = [[NSDateFormatter alloc] init];
		[timeFormatter setDateFormat:@"h:mm a"];
	}
	
	return [timeFormatter stringFromDate:self];
}

-(NSString*)dayOfMonth {
	if (dayOfMonthFormatter == nil) {
		dayOfMonthFormatter = [[NSDateFormatter alloc] init];
		[dayOfMonthFormatter setDateFormat:@"dd"];
	}
	
	return [dayOfMonthFormatter stringFromDate:self];
}

-(NSString*)month {
	if (monthFormatter == nil) {
		monthFormatter = [[NSDateFormatter alloc] init];
		[monthFormatter setDateFormat:@"MMM"];
	}
	
	return [monthFormatter stringFromDate:self];
}

-(NSString*)dayOfWeek {
	if (dayOfWeekFormatter == nil) {
		dayOfWeekFormatter = [[NSDateFormatter alloc] init];
		[dayOfWeekFormatter setDateFormat:@"EEEE"];
	}
	
	return [dayOfWeekFormatter stringFromDate:self];
}

-(NSString*)dayMonthString {
	if (dayMonthFormatter == nil) {
		dayMonthFormatter = [[NSDateFormatter alloc] init];
		[dayMonthFormatter setDateFormat:@"dd/MM"];
	}
	
	return [dayMonthFormatter stringFromDate:self];
}


-(NSString*)dayMonthYearString {
	if (dayMonthYearFormatter == nil) {
		dayMonthYearFormatter = [[NSDateFormatter alloc] init];
		[dayMonthYearFormatter setDateFormat:@"dd/MM/yyyy"];
	}
	
	return [dayMonthYearFormatter stringFromDate:self];
}

-(NSString*)shortHandDate {
	if (shortHandDateFormatter == nil) {
		shortHandDateFormatter = [[NSDateFormatter alloc] init];
		[shortHandDateFormatter setDateFormat:@"EE d MMMM yyyy"];
	}
	
	return [shortHandDateFormatter stringFromDate:self];
	
}

+(NSDate*)dateForRSSString:(NSString*)string {
	if (rssDateFormatter == nil) {
		rssDateFormatter = [[NSDateFormatter alloc] init];
		[rssDateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss zzzz"];
	}
	
	return [rssDateFormatter dateFromString:string];
}


+(NSString*)RSSStringForDate:(NSDate*)date {
	if (rssDateFormatter == nil) {
		rssDateFormatter = [[NSDateFormatter alloc] init];
		[rssDateFormatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss zzzz"];
	}
	
	return [rssDateFormatter stringFromDate:date];
}

-(BOOL)isWeekend {
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSRange weekdayRange = [calendar maximumRangeOfUnit:NSWeekdayCalendarUnit];
	NSDateComponents *components = [calendar components:NSWeekdayCalendarUnit fromDate:self];
	NSUInteger weekdayOfDate = [components weekday];
	
	if (weekdayOfDate == weekdayRange.location || weekdayOfDate == weekdayRange.length) {
		return TRUE;
	} else {
		return FALSE;
	}
}

+(NSDate*)dateFromMilliSecondString:(NSString*)string {
    
    double value = [string doubleValue] / 1000;
  
    return [NSDate dateWithTimeIntervalSince1970:value];
}

-(NSDate*)thisMorning
{
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:self];
	comps.hour = 1;
	comps.minute = 0;
	comps.second = 0;
	return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

-(NSDate*)midnight
{
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
	NSDateComponents *comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:self];
	comps.hour = 24;
	comps.minute = 0;
	comps.second = 0;
	return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

-(BOOL)isOnTheSameWeekAs:(NSDate*)date {
	
	unsigned unitFlags = NSWeekCalendarUnit;
	NSDateComponents * comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:self];
	NSDateComponents * comps2 = [[NSCalendar currentCalendar] components:unitFlags fromDate:date];

	if (comps.week == comps2.week)
		return YES;
	else
		return NO;
}

-(NSDate*)twoDaysAgo
{
	return [[NSDate alloc] initWithTimeInterval:-(SECSINADAY*2) sinceDate:self];
}

//Seven Days ago
-(NSDate*)sevenDaysAgo
{
	return [[NSDate alloc] initWithTimeInterval:-SECSINANWEEK sinceDate:self];
}

//28 days ago
-(NSDate*)twentyEightDaysAgo
{
	return [[NSDate alloc] initWithTimeInterval:-SECSIN28DAYS sinceDate:self];
}

-(NSDate*)twentyEightDaysLater
{
	return [[NSDate alloc] initWithTimeInterval:+SECSIN28DAYS sinceDate:self];
}

-(NSDate*)tenYearsLater 
{
	return [[NSDate alloc] initWithTimeInterval:315569260 sinceDate:self];	
}

-(NSDate*)hourAgo
{
	return [[NSDate alloc] initWithTimeInterval:-SECSINANHOUR sinceDate:self];
}

-(NSDate*)nextDay
{
	return [[NSDate alloc] initWithTimeInterval:SECSINADAY sinceDate:self];
}

-(NSDate*)prevDay
{
	return [[NSDate alloc] initWithTimeInterval:-SECSINADAY sinceDate:self];
}

-(int)dayOfMonthN {
	unsigned unitFlags = NSDayCalendarUnit;
	
	NSDateComponents * comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:self];

	return comps.day;
}

-(int)hour {
    unsigned unitFlags = kCFCalendarUnitHour;
	NSDateComponents * comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:self];
    return [comps hour];
}

-(BOOL)isOnTheSameDayAsDate:(NSDate*)date
{
	unsigned unitFlags = NSDayCalendarUnit | kCFCalendarUnitMonth | kCFCalendarUnitYear;
	NSDateComponents * comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:self];
	NSDateComponents * comps2 = [[NSCalendar currentCalendar] components:unitFlags fromDate:date];
	
	if (comps.day == comps2.day && comps.month == comps2.month && comps.year == comps2.year)
		return YES;
	else
		return NO;
	
	return NO;
}


@end
