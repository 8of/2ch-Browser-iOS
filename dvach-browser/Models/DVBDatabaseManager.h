//
//  DVBDatabaseManager.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 31/08/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YapDatabase/YapDatabase.h>

static NSString * const DB_COLLECTION_THREADS = @"kDbCollectionThreads";
static NSString * const DB_COLLECTION_THREAD_POSITIONS = @"kDbCollectionThreadPositions";

@interface DVBDatabaseManager : NSObject

@property (nonatomic, strong) YapDatabase *database;

+ (id)sharedDatabase;
/// Delete all threads from DB
- (void)clearAll;

@end
