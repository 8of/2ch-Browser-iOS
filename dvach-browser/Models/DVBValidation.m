//
//  DVBValidation.m
//  dvach-browser
//
//  Created by Mega on 12/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBValidation.h"

@interface DVBValidation ()

@end

@implementation DVBValidation

- (BOOL)checkBoardShortCodeWith:(NSString *)boardCode
{
    BOOL isBoardCodeNullString = [boardCode isEqualToString:@""];
    BOOL isBoardCodeWithoutSlash = ([boardCode rangeOfString:@"/"].location == NSNotFound);
    BOOL isBoardCodeWithoutQuote = ([boardCode rangeOfString:@"/\'"].location == NSNotFound);
    BOOL isBoardCodeWithoutDoubleQuote = ([boardCode rangeOfString:@"\""].location == NSNotFound);
    BOOL isBoardCodeWithoutSpace = ([boardCode rangeOfString:@" "].location == NSNotFound);
    
    // Check if all above is good.
    if (!isBoardCodeNullString &&
        isBoardCodeWithoutSlash &&
        isBoardCodeWithoutQuote &&
        isBoardCodeWithoutDoubleQuote &&
        isBoardCodeWithoutSpace)
    {
        return YES;
    }

    return NO;
}

@end
