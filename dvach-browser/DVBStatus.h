//
//  DVBStatus.h
//  dvach-browser
//
//  Created by Andy on 25/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVBStatus : NSObject

/**
 *  Server status integer - app gets it from my server.
 */
@property (nonatomic, readonly) NSUInteger status;

/**
 *  Board list version, app get it from server.
 */
@property (nonatomic, readonly) NSUInteger version;
@property (nonatomic, readonly) BOOL filterContent;

+ (instancetype)sharedStatus;

- (void)setStatus:(NSUInteger)status
       andVersion:(NSUInteger)version;
- (void)setFilterContent:(BOOL)filterContent;

@end