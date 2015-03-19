//
//  DVBStatus.m
//  dvach-browser
//
//  Created by Andy on 25/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBStatus.h"

@implementation DVBStatus

+ (instancetype)sharedStatus {
    static DVBStatus *sharedStatus = nil;
    
    if (!sharedStatus) {
        sharedStatus = [[self alloc] initPrivate];
    }
    
    return sharedStatus;
}

/**
 *  Not permitting to create multiple instances of Singleton DVBStatus
 *
 *  @return always nil
 */
- (instancetype)init {
    @throw [NSException exceptionWithName:@"Singleton" reason:@"Use +[DVBStatus sharedStatus]" userInfo:nil];
    
    return nil;
}

/**
 *  First time initing - set default vals.
 *
 *  @return DVBStatus
 */
- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _status = 0;
        _status = NO;
    }

    return self;
}

- (void)setStatus:(NSUInteger)status
       andVersion:(NSUInteger)version {
    _status = status;
    _version = version;
}

- (void)setFilterContent:(BOOL)filterContent {
    _filterContent = filterContent;
}

@end