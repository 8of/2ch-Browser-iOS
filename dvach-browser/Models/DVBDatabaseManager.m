//
//  DVBDatabaseManager.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 31/08/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBDatabaseManager.h"

static NSString * const DB_FILE = @"dvachDB.sqlite";

@implementation DVBDatabaseManager

#pragma mark - Collections IDs

+ (NSString *)dbCollectionThreads
{
  return @"kDbCollectionThreads";
}

+ (NSString *)dbCollectionThreadPositions
{
  return @"kDbCollectionThreadPositions";
}

#pragma mark - Construct DB

+ (id)sharedDatabase
{
  static DVBDatabaseManager *sharedMyManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedMyManager = [[self alloc] init];
  });
  return sharedMyManager;
}

- (id)init
{
  if (self = [super init]) {
    if (!_database) {
      _database = [[YapDatabase alloc] initWithPath:[self constructFullDbPath]];
    }
  }
  return self;
}

- (NSString *)constructFullDbPath
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *baseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();

  NSString *databaseName = DB_FILE;
  NSString *databasePath = [baseDir stringByAppendingPathComponent:databaseName];
  return databasePath;
}

#pragma mark - Change DB

- (void)clearAll
{
  YapDatabaseConnection *connection = [_database newConnection];
  [connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * transaction) {
    [transaction removeAllObjectsInAllCollections];
  }];
}

@end
