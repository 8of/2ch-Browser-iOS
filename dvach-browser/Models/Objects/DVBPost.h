//
//  DVBPost.h
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

@interface DVBPost : NSObject

typedef NS_ENUM(NSUInteger, DVBPostMediaType) {
    noMedia,
    image,
    webm
};

/// Number of the post
@property (nonatomic, strong, readonly) NSString *num;
/// Subject of the post (for section title in thread View Controller and thread View Controller title)
@property (nonatomic, strong, readonly) NSString *subject;
/// Text of post message.
@property (nonatomic, strong, readonly) NSAttributedString *comment;
/// Type of the media in the post
@property (nonatomic, assign, readonly) DVBPostMediaType mediaType;
/// Path for post's full image
@property (nonatomic, strong, readonly) NSString *path;
/// Path for post's thumnail image
@property (nonatomic, strong, readonly) NSString *thumbPath;
/// Array of pathes for full images attached to post
@property (nonatomic, strong, readonly) NSArray *pathesArray;
/// Array of pathes for thumbnail images attached to post
@property (nonatomic, strong, readonly) NSArray *thumbPathesArray;
/// Absolute date
@property (nonatomic, strong, readonly) NSString *date;
/// Relative date to NOW date
@property (nonatomic, strong, readonly) NSString *dateAgo;
/// Name of the author of the post
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, assign, readonly) BOOL sage;
/// Replies to this post from other posts in the thread / need to be mutable, as we change it afer creating
@property (nonatomic, strong) NSMutableArray *replies;
/// Replies to other posts in this post, children of the same thread / need to be mutable, as we change it afer creating
@property (nonatomic, strong) NSMutableArray *repliesTo;

- (instancetype)initWithNum:(NSString *)postNum subject:(NSString *)postSubject comment:(NSAttributedString *)postComment path:(NSString *)postPicPath thumbPath:(NSString *)postThumbPath pathesArray:(NSArray *)postPathesArray thumbPathesArray:(NSArray *)postThumbPathesArray date:(NSString *)postDate dateAgo:(NSString *)postDateAgo repliesTo:(NSMutableArray *)postRepliesTo mediaType:(DVBPostMediaType)mediaType name:(NSString *)name sage:(BOOL)sage;

@end