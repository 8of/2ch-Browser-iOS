//
//  DVBAsyncThreadViewController.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 18/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBAsyncThreadViewController.h"
#import "DVBCommon.h"
#import "DVBConstants.h"
#import "DVBThreadModel.h"
#import "DVBCreatePostViewControllerDelegate.h"
#import "DVBPostStyler.h"
#import "DVBPostViewModel.h"
#import "DVBPostNode.h"
#import "ARChromeActivity.h"

NS_ASSUME_NONNULL_BEGIN

static CGFloat const MAX_OFFSET_DIFFERENCE_TO_SCROLL_AFTER_POSTING = 500.0f;

@interface DVBAsyncThreadViewController () <ASTableDataSource, ASTableDelegate, DVBCreatePostViewControllerDelegate>

@property (nonatomic, strong) DVBThreadModel *threadModel;

@property (nonatomic, strong) ASTableNode *tableNode;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong, nullable) UIRefreshControl *bottomRefreshControl;
@property (nonatomic, strong) NSArray <DVBPostViewModel *> *posts;
/// New posts count added with last thread update
@property (nonatomic, strong) NSNumber *previousPostsCount;

@end

@implementation DVBAsyncThreadViewController

- (instancetype)initWithBoardCode:(NSString *)boardCode andThreadNumber:(NSString *)threadNumber andThreadSubject:(NSString *)subject
{
    _tableNode = [[ASTableNode alloc] initWithStyle:UITableViewStylePlain];
    self = [super initWithNode:_tableNode];
    if (self) {
        _threadModel = [[DVBThreadModel alloc] initWithBoardCode:boardCode andThreadNum:threadNumber];
        [self createRightButton];
        [self setupTableNode];
        [self initialThreadLoad];
    }
    return self;
}

#pragma mark - View stuff

- (void)setupTableNode
{
    [UIApplication sharedApplication].keyWindow.backgroundColor = [DVBPostStyler postCellBackgroundColor];

    _tableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableNode.view.contentInset = UIEdgeInsetsMake([DVBPostStyler elementInset]-1, 0, [DVBPostStyler elementInset], 0);
    _tableNode.backgroundColor = [DVBPostStyler postCellBackgroundColor];
    _tableNode.delegate = self;
    _tableNode.dataSource = self;
    _tableNode.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableNode.view.showsVerticalScrollIndicator = NO;
    _tableNode.view.showsHorizontalScrollIndicator = NO;
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self
                        action:@selector(reloadThread)
              forControlEvents:UIControlEventValueChanged];
    [_tableNode.view addSubview:_refreshControl];
}

- (void)createRightButton
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Compose"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(openNewPost)];
    self.navigationItem.rightBarButtonItem = item;
}

#pragma mark - Data management and processing

/// Get data for thread from Db if any
- (void)initialThreadLoad
{
    weakify(self);
    [_threadModel checkPostsInDbForThisThreadWithCompletion:^(NSArray *posts) { // array of DVBPost
        strongify(self);
        if (!self || !posts) { return; }
        _posts = [self convertPostsToViewModel:posts];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_tableNode reloadData];
        });
        [self reloadThread];
    }];
}

- (NSArray <DVBPostViewModel *> *)convertPostsToViewModel:(NSArray <DVBPost *> *)posts
{
    NSMutableArray <DVBPostViewModel *> *vmPosts = [@[] mutableCopy];
    [posts enumerateObjectsUsingBlock:^(DVBPost *post, NSUInteger idx, BOOL * _Nonnull stop) {
        DVBPostViewModel *vm = [[DVBPostViewModel alloc] initWithPost:post andIndex:idx];
        [vmPosts addObject:vm];
    }];
    return [vmPosts copy];
}

#pragma mark - ASTableNode

- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBPostViewModel *post = _posts[indexPath.row];
    return ^{
        return [[DVBPostNode alloc] initWithPost:post];
    };
}

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
    return _posts.count;
}

#pragma - Network Loading

- (void)reloadThread
{
    weakify(self);
    [self getPostsWithBoard:_threadModel.boardCode
                  andThread:_threadModel.threadNum
              andCompletion:^(NSArray *posts)
     {
         strongify(self);
         if (!self) { return; }
         if (!posts) {
             // [self showMessageAboutError];
             return;
         }
         _posts = [self convertPostsToViewModel:posts];
         dispatch_async(dispatch_get_main_queue(), ^{
             [_tableNode reloadData];
             [_refreshControl endRefreshing];
             [_bottomRefreshControl endRefreshing];
             [self checkNewPostsCount];
             // self.tableView.backgroundView = nil;
         });

         _refreshControl.enabled = YES;
         _bottomRefreshControl.enabled = YES;
     }];
}

/// Get data from 2ch server
- (void)getPostsWithBoard:(NSString *)board andThread:(NSString *)threadNum andCompletion:(void (^)(NSArray *))completion
{
    weakify(self);
    [_threadModel reloadThreadWithCompletion:^(NSArray *completionsPosts) {
        strongify(self);
        if (!self) { return; }
        completion(completionsPosts);
    }];
}

#pragma mark - New posts count handling

/// Check if server have new posts and scroll if user already scrolled to the end
- (void)checkNewPostsCount
{
    NSInteger additionalPostCount = _posts.count - _previousPostsCount.integerValue;

    if (([_previousPostsCount integerValue] > 0) &&
        (additionalPostCount > 0))
    {
        NSNumber *newMessagesCount = @(additionalPostCount);

        [self performSelector:@selector(newMessagesPromptWithNewMessagesCount:)
                   withObject:newMessagesCount
                   afterDelay:0.5];
    }

    NSNumber *postsCountNewValue = @(_posts.count);

    // _threadsScrollPositionManager.threadPostCounts[_threadNum] = postsCountNewValue;
    _previousPostsCount = postsCountNewValue;

    // _refreshButton.enabled = YES;
}

#pragma mark - Prompt

/// Show and hide message after delay
- (void)showPromptWithMessage:(NSString *)message
{
    self.navigationItem.prompt = message;
    [self performSelector:@selector(clearPrompt)
               withObject:nil
               afterDelay:1.5];
}

/// Clear prompt from any status / error messages.
- (void)clearPrompt
{
    // Prevent crashes
    if (!self || self.navigationItem == nil || self.navigationItem.prompt == nil) { return; }
    self.navigationItem.prompt = nil;
}

/// Show prompt with cound of new messages
- (void)newMessagesPromptWithNewMessagesCount:(NSNumber *)newMessagesCount
{
    [self showPromptWithMessage:[NSString stringWithFormat:@"%@ %@", @(newMessagesCount.integerValue), NSLS(@"PROMPT_NEW_MESSAGES")]];

    // Check if difference is not too big (scroll isn't needed if user saw only half of the thread)

    CGFloat offsetDifference = self.tableNode.view.contentSize.height - self.tableNode.view.contentOffset.y - self.tableNode.view.bounds.size.height;

    if (offsetDifference < MAX_OFFSET_DIFFERENCE_TO_SCROLL_AFTER_POSTING &&
        _posts.count > 10) // Prevent scrolling when posts count isn't high enough
    {
        [NSTimer scheduledTimerWithTimeInterval:2.0
                                         target:self
                                       selector:@selector(scrollToBottom)
                                       userInfo:nil
                                        repeats:NO];
    }
}

- (void)scrollToBottom
{
//    CGFloat heightDifference = self.tableView.contentSize.height - self.tableView.frame.size.height + self.navigationController.toolbar.frame.size.height;
//
//    CGPoint pointToScrollTo = CGPointMake(0, heightDifference);
//
//    [self.tableView setContentOffset:pointToScrollTo
//                            animated:YES];
}

#pragma mark - Routing

- (void)openNewPost
{

}

@end

NS_ASSUME_NONNULL_END
