//
//  DVBThreadModel.h
//  dvach-browser
//
//  Created by Andy on 20/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DVBPost.h"

@interface DVBThreadModel : NSObject

/**
 *  Array contains all posts in the thread
 */
@property (nonatomic, strong, readonly) NSArray *postsArray;
// array of all post thumb images in thread
@property (nonatomic, strong) NSArray *thumbImagesArray;
// array of all post full images in thread
@property (nonatomic, strong) NSArray *fullImagesArray;

- (instancetype)initWithBoardCode:(NSString *)boardCode andThreadNum:(NSString *)threadNum;

/**
 *  Entirely reload post list in the thread
 */
- (void)reloadThreadWithCompletion:(void (^)(NSArray *))completion;

// Report thread
- (void)reportThreadWithBoardCode:(NSString *)board andThread:(NSString *)thread andComment:(NSString *)comment;
/**
 *  Generate array of thumbnail images from posts
 *
 *  @param postsArray array of posts
 *
 *  @return array of thumbnail images
 */
- (NSArray *)thumbImagesArrayForPostsArray:(NSArray *)postsArray;
/**
 *  Generate array of full images from posts
 *
 *  @param postsArray array of posts
 *
 *  @return array of full images
 */
- (NSArray *)fullImagesArrayForPostsArray:(NSArray *)postsArray;

@end
