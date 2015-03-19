//
//  DVBValidation.m
//  dvach-browser
//
//  Created by Mega on 12/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBValidation.h"

@interface DVBValidation ()

@property (strong, nonatomic) NSArray *badBoards;

@end

@implementation DVBValidation

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self makeBadBoardsArray];
        _filterContent = YES;
    }
    return self;
}

/**
 *  Temp solutions just to move out this method from controller.
 *  Need to create another class for this purpose later.
 */
- (void)makeBadBoardsArray
{
    if (!_badBoards)
    {
        _badBoards =[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"BadBoards" ofType:@"plist"]];
    }
}

- (BOOL)checkBadBoardWithBoard:(NSString *)board
{
    BOOL isBoardInBadBoardsArray = [_badBoards containsObject: board];
    return isBoardInBadBoardsArray;
}

- (BOOL)checkBoardShortCodeWith:(NSString *)boardCode
{
    BOOL isBoardCodeNullString = [boardCode isEqualToString:@""];
    BOOL isBoardCodeWithoutSlash = ([boardCode rangeOfString:@"/"].location == NSNotFound);
    BOOL isBoardCodeWithoutQuote = ([boardCode rangeOfString:@"/\'"].location == NSNotFound);
    BOOL isBoardCodeWithoutDoubleQuote = ([boardCode rangeOfString:@"\""].location == NSNotFound);
    BOOL isBoardCodeWithoutSpace = ([boardCode rangeOfString:@" "].location == NSNotFound);
    
    /**
     *  Check if all above is good.
     */
    if ((!isBoardCodeNullString) && (isBoardCodeWithoutSlash) && (isBoardCodeWithoutQuote) && (isBoardCodeWithoutDoubleQuote) && (isBoardCodeWithoutSpace)) {
        return YES;
    }

    return NO;
}

@end
