//
//  DVBBadPost.m
//  dvach-browser
//
//  Created by Andy on 08/11/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBBadPost.h"

@implementation DVBBadPost

#pragma mark NSCoding

#define kNum @"num"
#define kThreadOrNot @"threadOrNot"

- (instancetype)initWithNum:(NSString *)postNum threadOrNot:(BOOL)trOrNt {
    self = [super init];
    if (self) {
        _num = postNum;
        _threadOrNot = trOrNt;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_num forKey:kNum];
    [aCoder encodeBool:_threadOrNot forKey:kThreadOrNot];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _num = [aDecoder decodeObjectForKey:kNum];
        _threadOrNot = [aDecoder decodeBoolForKey:kThreadOrNot];
    }
    
    return self;
}

@end