//
//  DVBThread.m
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBThread.h"

@implementation DVBThread

- (instancetype)initWithNum:(NSString *)threadNum Subject:(NSString *)threadTitle opComment:(NSString *)threadOpComment postsCount:(NSNumber *)threadPostsCount thumbPath:(NSString *)threadThumbPath andTimeSinceFirstPost:(NSString *)timeSinceFirstPost
{
    self = [super init];
    if (self) {
        _num = threadNum;
        _subject = threadTitle;
        _comment = threadOpComment;
        _postsCount = threadPostsCount;
        _thumbnail = threadThumbPath;
        _timeSinceFirstPost = timeSinceFirstPost;
    }
    return self;
}

@end