//
//  DVBThreadModel.h
//  dvach-browser
//
//  Created by Andy on 20/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVBThreadModel : NSObject

@property (nonatomic, strong, readonly) NSString *boardCode;
@property (nonatomic, strong, readonly) NSString *threadNum;

/// Array contains all posts in the thread
@property (nonatomic, strong, readonly) NSArray *postsArray;
/// Array of all post thumb images in thread
@property (nonatomic, strong) NSArray *thumbImagesArray;
/// Array of all post full images in thread
@property (nonatomic, strong) NSArray *fullImagesArray;

- (instancetype)initWithBoardCode:(NSString *)boardCode andThreadNum:(NSString *)threadNum;

/// Check if there are any posts in DB for thread num (thread num is stored inside DVBThreadModel instance)
- (void)checkPostsInDbForThisThreadWithCompletion:(void (^)(NSArray *))completion;

/// Entirely reload post list in the thread
- (void)reloadThreadWithCompletion:(void (^)(NSArray *))completion;

/// Report thread to admins
- (void)reportThread;
- (void)bookmarkThreadWithTitle:(NSString *)title;
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

- (void)storedThreadPosition:(void (^)(NSIndexPath *))completion;
- (void)storeThreadPosition:(NSIndexPath *)indexPath;

@end
