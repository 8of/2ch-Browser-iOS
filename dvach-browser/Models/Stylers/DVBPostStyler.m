//
//  DVBPostStyler.m
//  dvach-browser
//
//  Created by Andy on 17/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBCommon.h"
#import "DVBPostStyler.h"
#import "DVBBoardStyler.h"

@implementation DVBPostStyler

+ (UIColor *)postCellBackgroundColor
{
    return [DVBBoardStyler threadCellBackgroundColor];
}

+ (UIColor *)postCellInsideBackgroundColor
{
    return [DVBBoardStyler threadCellInsideBackgroundColor];
}

+ (UIColor *)textColor
{
    return [DVBBoardStyler textColor];
}

+ (CGColorRef)borderColor
{
    return [DVBBoardStyler borderColor];
}

+ (CGFloat)mediaSize
{
    return IS_IPAD ? 150 : 62;
}

+ (CGFloat)elementInset
{
    return [DVBBoardStyler elementInset];
}

+ (CGFloat)innerInset
{
    return 2*[self elementInset];
}

+ (CGFloat)cornerRadius
{
    return [DVBBoardStyler cornerRadius];
}

+ (BOOL)ageCheckNotPassed
{
    return [DVBBoardStyler ageCheckNotPassed];
}

@end
