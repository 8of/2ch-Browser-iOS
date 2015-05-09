//
//  DVBThread.m
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBThread.h"

@implementation DVBThread

- (instancetype)initWithNum:(NSString *)threadNum Subject:(NSString *)threadTitle opComment:(NSString *)threadOpComment filesCount:(NSNumber *)threadFilesCount postsCount:(NSNumber *)threadPostsCount thumbPath:(NSString *)threadThumbPath fullPath:(NSString *)threadFullPath
{
    self = [super init];
    if (self) {
        _num = threadNum;
        _subject = threadTitle;
        _comment = threadOpComment;
        _filesCount = threadFilesCount;
        _postsCount = threadPostsCount;
        _thumbnail = threadThumbPath;
        _fullImage = threadFullPath;
    }
    return self;
}

@end