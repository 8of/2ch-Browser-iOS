//
//  DateFormatter.m
//  dvach-browser
//
//  Created by Andy on 28/08/14.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBCommon.h"
#import "DateFormatter.h"

@implementation DateFormatter

+ (NSString *)dateFromTimestamp:(NSInteger)timestamp
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    
    static NSCalendarUnit units;
    units = NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth;
    NSDateComponents *components = [[NSCalendar currentCalendar] components:units fromDate:date toDate:[NSDate date] options:0];

    if (components.month > 0) {
        static NSDateFormatter *formatter;
        formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        [formatter setDateFormat:@"dd.MM.yy"];
        return [formatter stringFromDate:date];
    } else if (components.day > 0) {
        return [NSString stringWithFormat:NSLS(@"DATE_FORMATTER_DAYS"), (long)components.day];
    } else if (components.hour > 0) {
        return [NSString stringWithFormat:NSLS(@"DATE_FORMATTER_HOURS"), (long)components.hour];
    } else if (components.minute > 0){
        return [NSString stringWithFormat:NSLS(@"DATE_FORMATTER_MINS"), (long)components.minute];
    } else if (components.second > 15){
        return [NSString stringWithFormat:NSLS(@"DATE_FORMATTER_SECS"), (long)components.second];
    } else {
        return NSLS(@"DATE_FORMATTER_NOW");
    }
    return [NSString stringWithFormat:@"%ld %ld", (long)components.minute, (long)components.second];
}

@end
