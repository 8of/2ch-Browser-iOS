//
//  DVBBoardObj.m
//  dvach-browser
//
//  Created by Andy on 16/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBBoardObj.h"

static NSString *const CODER_KEY_FOR_BOARDID = @"boardId";
static NSString *const CODER_KEY_FOR_NAME = @"name";
static NSString *const CODER_KEY_FOR_PAGES = @"pages";

@implementation DVBBoardObj

- (instancetype)initWithId:(NSString *)boardId
                   andName:(NSString *)name {
    self = [super init];
    if (self) {
        _boardId = boardId;
        _name = name;
        _pages = 0;
    }
    
    return self;
}

- (instancetype)initWithId:(NSString *)boardId
                   andName:(NSString *)name
                  andPages:(NSUInteger)pages {
    self = [super init];
    if (self) {
        _boardId = boardId;
        _name = name;
        _pages = pages;
    }
    
    return self;
}

#pragma  mark - Encodeing/Decoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _boardId = [aDecoder decodeObjectForKey:CODER_KEY_FOR_BOARDID];
        _name = [aDecoder decodeObjectForKey:CODER_KEY_FOR_NAME];
        _pages = [aDecoder decodeIntegerForKey:CODER_KEY_FOR_PAGES];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_boardId forKey:CODER_KEY_FOR_BOARDID];
    [aCoder encodeObject:_name forKey:CODER_KEY_FOR_NAME];
    [aCoder encodeInteger:_pages forKey:CODER_KEY_FOR_PAGES];
}

@end