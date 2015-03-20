//
//  DVBPostObj.h
//  dvach-browser
//
//  Created by Andy on 13/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

/**
 *  Object for storing information about specific post.
 *
 *  @return Object with full info about post.
 */

#import <Foundation/Foundation.h>

@interface DVBPostObj : NSObject

/**
 *  Number of the post.
 */
@property (strong, nonatomic) NSString *num;
/**
 *  Subject of the post (for section title in thread View Controller and thread View Controller title).
 */
@property (strong, nonatomic) NSString *subject;
/**
 *  Text of post message.
 */
@property (strong, nonatomic) NSAttributedString *comment;
/**
 *  Path for post's full image.
 */
@property (strong, nonatomic) NSString *path;
/**
 *  Path for post's thumnail image.
 */
@property (strong, nonatomic) NSString *thumbPath;

- (instancetype)initWithNum:(NSString *)postNum
                    subject:(NSString *)postSubject
                    comment:(NSAttributedString *)postComment
                       path:(NSString *)postPicPath
                  thumbPath:(NSString *)postThumbPath;

@end