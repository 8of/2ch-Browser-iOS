//
//  DVBComment.m
//  dvach-browser
//
//  Created by Mega on 28/01/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBComment.h"

@implementation DVBComment

@synthesize comment;

#pragma mark Singleton Methods

+ (id)sharedComment
{
    static DVBComment *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init
{
    if (self = [super init]) {
        if (!self.comment) {
            self.comment = @"";
        }
        /**
         *  Additional preparations here.
         */
    }
    return self;
}

@end