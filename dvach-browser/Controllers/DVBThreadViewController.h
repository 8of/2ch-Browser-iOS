//
//  DVBThreadViewController.h
//  dvach-browser
//
//  Created by Andy on 11/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UrlNinja.h"
#import "DVBThreadsScrollPositionManager.h"

#import "DVBCommonTableViewController.h"

@interface DVBThreadViewController : DVBCommonTableViewController

/// Board shortcode
@property (strong, nonatomic) NSString *boardCode;
/// Thread number
@property (strong, nonatomic) NSString *threadNum;
/// Subject for section title in board View Controller
@property (strong, nonatomic) NSString *threadSubject;
/// Array of answers for specific post (set it if we need to show answers for post and no entire thread)
@property (nonatomic, strong) NSArray *answersToPost;
@property (nonatomic, assign) BOOL isItPostItself;
@property (nonatomic, strong) NSArray *allThreadPosts;
/// String to quote in answer to the post
@property (nonatomic, strong) NSString *quoteString;
/// Post number - use if we show answers for specific post
@property (nonatomic, strong) NSString *postNum;

// Auto scrolling stuff
@property (nonatomic, strong) DVBThreadsScrollPositionManager *threadsScrollPositionManager;
@property (nonatomic, assign) CGFloat topBarDifference;
@property (nonatomic, strong) NSNumber *autoScrollTo;

- (BOOL)isLinkInternalWithLink:(UrlNinja *)url;

- (void)openMediaWithUrlString:(NSString *)fullUrlString;
/// Open single post
- (void)openPostWithUrlNinja:(UrlNinja *)urlNinja;
/// Open whole new thread
- (void)openThreadWithUrlNinja:(UrlNinja *)urlNinja;
- (void)callShareControllerWithUrlString:(NSString *)urlString;

- (void)showMessageAboutDataLoading;
- (void)showMessageAboutError;

/// Only for simple redirecting Answer View Controller opening - nothing more!
- (void)openPostingControllerFromThisOne;

@end
