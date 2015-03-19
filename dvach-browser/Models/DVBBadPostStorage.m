//
//  DVBBadPostStorge.m
//  dvach-browser
//
//  Created by Andy on 08/11/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBBadPostStorage.h"

@implementation DVBBadPostStorage

static NSString *const BAD_POSTS_ARCHIVE_FILE = @"boardEntryCell";

//#define kBadPostsArchiveFile @"badposts.archive"

- (NSString *)badPostsArchivePath {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories firstObject];
    return [documentDirectory stringByAppendingPathComponent:BAD_POSTS_ARCHIVE_FILE];
}

- (BOOL)saveChanges {
    NSString *path = [self badPostsArchivePath];
    return [NSKeyedArchiver archiveRootObject:self.badPostsArray toFile:path];
}

@end
