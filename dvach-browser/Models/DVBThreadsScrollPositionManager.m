//
//  DVBThreadsScrollPositionManager.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 09/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBThreadsScrollPositionManager.h"

@implementation DVBThreadsScrollPositionManager

@synthesize threads;

+ (id)sharedThreads
{
    static DVBThreadsScrollPositionManager *sharedMyManger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManger = [[self alloc] init];
    });
    return sharedMyManger;
}

- (id)init
{
    if (self = [super init]) {
        if (!self.threads) {
            self.threads = [@{} mutableCopy];
        }
    }
    return self;
}

@end
