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

//

@interface DVBThread : NSObject

/**
 *  Number of the open post of the thread.
 */
@property (strong, nonatomic) NSString *num;
/**
 *  Subject of the thread (for section title in board View Controller and thread View Controller title).
 */
@property (strong, nonatomic) NSString *subject;
/**
 *  Text of open post message.
 */
@property (strong, nonatomic) NSString *comment;
/**
 *  Count of files inside the thread.
 */
@property (strong, nonatomic) NSNumber *filesCount;
/**
 *  Count of posts inside given thread.
 */
@property (strong, nonatomic) NSNumber *postsCount;
/**
 *  Path for open post's thumnail image.
 */
@property (strong, nonatomic) NSString *thumbnail;

- (instancetype)initWithNum:(NSString *)threadNum
                    Subject:(NSString *)threadTitle
                  opComment:(NSString *)threadOpComment
                 filesCount:(NSNumber *)threadFilesCount
                 postsCount:(NSNumber *)threadPostsCount
                  thumbPath:(NSString *)threadThumbPath;

@end