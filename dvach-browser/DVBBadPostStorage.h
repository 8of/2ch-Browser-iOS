//
//  DVBBadPostStorge.h
//  dvach-browser
//
//  Created by Andy on 08/11/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

/**
 *  storage for storing bad posts, marked by user
 */

#import <Foundation/Foundation.h>

@interface DVBBadPostStorage : NSObject

@property NSMutableArray *badPostsArray;

/**
 *  path for storing
 *
 *  @return path on the device
 */
- (NSString *)badPostsArchivePath;
/**
 *  for checking changes saved or not
 *
 *  @return YES if saved
 */
- (BOOL)saveChanges;

@end