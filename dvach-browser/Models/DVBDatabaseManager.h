//
//  DVBDatabaseManager.h
//  dvach-browser
//
//  Created by Andy on 31/08/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YapDatabase/YapDatabase.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVBDatabaseManager : NSObject

@property (class, nonatomic, strong, readonly) NSString *dbCollectionThreads;
@property (class, nonatomic, strong, readonly) NSString *dbCollectionThreadPositions;
@property (nonatomic, strong) YapDatabase *database;

+ (id)sharedDatabase;
/// Delete all threads from DB
- (void)clearAll;

@end
NS_ASSUME_NONNULL_END
