//
//  DVBThreadModel.h
//  dvach-browser
//
//  Created by Andy on 20/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVBBadPostStorage.h"

@interface DVBThreadModel : NSObject

/**
 *  Array contains all posts in the thread
 */
@property (nonatomic, strong, readonly) NSMutableArray *postsArray;
// array of all post thumb images in thread
@property (nonatomic, strong) NSMutableArray *thumbImagesArray;
// array of all post full images in thread
@property (nonatomic, strong) NSMutableArray *fullImagesArray;

- (instancetype)initWithBoardCode:(NSString *)boardCode
                     andThreadNum:(NSString *)threadNum;

/**
 *  Entirely reload post list in the thread
 */
- (void)reloadThreadWithCompletion:(void (^)(NSArray *))completion;

// flag and delete post
- (void)flagPostWithIndex:(NSUInteger)index
        andFlaggedPostNum:(NSString *)flaggedPostNum
      andOpAlreadyDeleted:(BOOL)opAlreadyDeleted;

@end
