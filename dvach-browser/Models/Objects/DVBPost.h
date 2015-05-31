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
#import <Mantle/Mantle.h>

@interface DVBPost : MTLModel <MTLJSONSerializing>

/// Number of the post
@property (nonatomic, strong) NSString *num;
/// Subject of the post (for section title in thread View Controller and thread View Controller title)
@property (nonatomic, strong, readonly) NSString *subject;
/// Text of post message.
@property (nonatomic, strong) NSAttributedString *comment;
/// Array of pathes for full images attached to post
@property (nonatomic, strong) NSArray *pathesArray;
/// Array of pathes for thumbnail images attached to post
@property (nonatomic, strong) NSArray *thumbPathesArray;
/// Relative date to NOW date
@property (nonatomic, strong, readonly) NSString *dateAgo;
/// Name of the author of the post
@property (nonatomic, strong, readonly) NSString *name;
/// Replies to this post from other posts in the thread / need to be mutable, as we change it afer creating
@property (nonatomic, strong) NSMutableArray *replies;
/// Replies to other posts in this post, children of the same thread / need to be mutable, as we change it afer creating
@property (nonatomic, strong) NSMutableArray *repliesTo;

@end