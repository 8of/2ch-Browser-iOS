//
//  DVBBoardStyler.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 16/11/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBCommon.h"
#import "DVBConstants.h"
#import "DVBBoardStyler.h"

@implementation DVBBoardStyler

+ (UIColor *)threadCellBackgroundColor
{
    return [self isDarkTheme] ? [UIColor blackColor] : [UIColor colorWithRed:0.95 green:0.96 blue:0.97 alpha:1];
}

+ (UIColor *)threadCellInsideBackgroundColor
{
    return [self isDarkTheme] ? CELL_BACKGROUND_COLOR : [UIColor whiteColor];
}

+ (UIColor *)textColor
{
    return [self isDarkTheme] ? DARK_CELL_TEXT_COLOR : [UIColor blackColor];
}

+ (CGColorRef)borderColor
{
    UIColor *color = [self isDarkTheme] ? [UIColor colorWithRed:(38.0/255.0) green:(38.0/255.0) blue:(38.0/255.0) alpha:1] : [UIColor lightGrayColor];
    return [color CGColor];
}

+ (CGFloat)mediaSize
{
    return IS_IPAD ? 150 : 100;
}

+ (CGFloat)elementInset
{
    return 10;
}

+ (CGFloat)cornerRadius
{
    return IS_IPAD ? 6 : 3;
}

+ (BOOL)isDarkTheme
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME];
}

+ (BOOL)ageCheckNotPassed
{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_AGE_CHECK_STATUS];
}

@end
