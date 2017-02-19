//
//  DVBThreadControllerTableViewManager.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 14/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "DVBCommon.h"
#import "DVBConstants.h"
#import "DVBPost.h"

@class DVBThreadViewController;

@interface DVBThreadControllerTableViewManager : NSObject <UITableViewDelegate, UITableViewDataSource>

- (instancetype)initWith:(DVBThreadViewController *)threadViewController;

/// Array of posts inside this thread
@property (nonatomic, strong) NSArray *postsArray;

/// Array of all post thumb images in thread
@property (nonatomic, strong) NSArray *thumbImagesArray;
/// Array of all post full images in thread
@property (nonatomic, strong) NSArray *fullImagesArray;

/// Array of answers for specific post (set it if we need to show answers for post and no entire thread)
@property (nonatomic, strong) NSArray *answersToPost;

@end
