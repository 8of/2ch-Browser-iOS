//
//  DVBThread.h
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

/**
 *  Object for storing information about specific thread
 *
 *  @return Object with full info about board
 */

#import <Foundation/Foundation.h>

@interface DVBThread : NSObject

/// UID of the open post of the thread.
@property (nonatomic, strong) NSString *num;
/// Subject of the thread
@property (nonatomic, strong) NSString *subject;
/// Text of open post message.
@property (nonatomic, strong) NSString *comment;
/// Count of files inside the thread.
@property (nonatomic, strong) NSNumber *filesCount;
/// Count of posts inside given thread.
@property (nonatomic, strong) NSNumber *postsCount;
/// Path for open post's thumnail image
@property (nonatomic, strong) NSString *thumbnail;

@property (nonatomic, strong) NSString *timeSinceFirstPost;

- (instancetype)initWithNum:(NSString *)threadNum Subject:(NSString *)threadTitle opComment:(NSString *)threadOpComment filesCount:(NSNumber *)threadFilesCount postsCount:(NSNumber *)threadPostsCount thumbPath:(NSString *)threadThumbPath andTimeSinceFirstPost:(NSString *)timeSinceFirstPost;

@end