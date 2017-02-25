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
#import "DVBThreadDelegate.h"
#import "DVBThreadModel.h"
#import "DVBCreatePostViewControllerDelegate.h"
#import "DVBPostStyler.h"
#import "DVBPostViewModel.h"
#import "DVBPostNode.h"
#import "DVBUrls.h"

#import "DVBMediaOpener.h"
#import "DVBThreadUIGenerator.h"
#import "DVBRouter.h"
#import "DVBComment.h"
#import "UrlNinja.h"

NS_ASSUME_NONNULL_BEGIN

static CGFloat const MAX_OFFSET_DIFFERENCE_TO_SCROLL_AFTER_POSTING = 500.0f;

@interface DVBAsyncThreadViewController () <ASTableDataSource, ASTableDelegate, DVBCreatePostViewControllerDelegate, DVBThreadDelegate>

@property (nonatomic, strong, nullable) DVBThreadModel *threadModel;

@property (nonatomic, strong) ASTableNode *tableNode;
@property (nonatomic, strong, nullable) UIRefreshControl *refreshControl;
// @property (nonatomic, strong, nullable) UIRefreshControl *bottomRefreshControl;
@property (nonatomic, strong) NSArray <DVBPostViewModel *> *posts;
@property (nonatomic, strong, nullable) NSArray <DVBPostViewModel *> *allPosts;

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
        self.title = [DVBThreadUIGenerator titleWithSubject:subject
                                               andThreadNum:threadNumber];
        [self createRightButton];
        [self setupTableNode];
        [self initialThreadLoad];
        [self fillToolbar];
    }
    return self;
}

- (instancetype)initWithPostNum:(NSString *)postNum answers:(NSArray <DVBPostViewModel *> *)answers allPosts:(NSArray <DVBPostViewModel *> *)allPosts
{
    _tableNode = [[ASTableNode alloc] initWithStyle:UITableViewStylePlain];
    self = [super initWithNode:_tableNode];
    if (self) {
        _posts = answers;
        _allPosts = allPosts;
        self.title = postNum;
        [self setupTableNode];
        [self initialThreadLoad];
    }
    return self;
}

#pragma mark - View stuff

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!_allPosts) {
        [self.navigationController setToolbarHidden:NO animated:YES];
    }
}

- (void)setupTableNode
{
    [DVBThreadUIGenerator styleTableNode:_tableNode];
    _tableNode.delegate = self;
    _tableNode.dataSource = self;

    if (!_allPosts) {
        [self addTopRefreshControl];
        [self addBottomRefreshControl];
    }
}

- (void)addTopRefreshControl
{
    _refreshControl = [DVBThreadUIGenerator refreshControlFor:_tableNode.view
                                                       target:self
                                                       action:@selector(reloadThread)];
}

- (void)addBottomRefreshControl
{
//    _bottomRefreshControl = [UIRefreshControl new];
//    _bottomRefreshControl.triggerVerticalOffset = 80.;
//    [_bottomRefreshControl addTarget:self action:@selector(reloadThread) forControlEvents:UIControlEventValueChanged];
//    _tableNode.view.bottomRefreshControl = _bottomRefreshControl;
//    [_tableNode.view sendSubviewToBack:_bottomRefreshControl];
}

- (void)createRightButton
{
    self.navigationItem.rightBarButtonItem = [DVBThreadUIGenerator composeItemTarget:self action:@selector(composeAction)];
}

- (void)fillToolbar
{
    self.toolbarItems = [DVBThreadUIGenerator toolbarItemsTarget:self
                                                    scrollBottom:@selector(scrollToBottom)
                                                        bookmark:@selector(bookmarkAction)
                                                           share:@selector(shareAction)
                                                            flag:@selector(flagAction)
                                                          reload:@selector(reloadThread)];
}

#pragma mark - Data management and processing

/// Get data for thread from Db if any
- (void)initialThreadLoad
{
    weakify(self);
    [_threadModel checkPostsInDbForThisThreadWithCompletion:^(NSArray *posts) { // array of DVBPost
        strongify(self);
        if (!self) { return; }
        if (!posts) {
            [self reloadThread];
            return;
        }
        _posts = [self convertPostsToViewModel:posts forAnswer:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_tableNode reloadData];
        });
        [self reloadThread];
    }];
}

- (NSArray <DVBPostViewModel *> *)convertPostsToViewModel:(NSArray <DVBPost *> *)posts forAnswer:(BOOL)forAnswer
{
    NSMutableArray <DVBPostViewModel *> *vmPosts = [@[] mutableCopy];
    [posts enumerateObjectsUsingBlock:^(DVBPost *post, NSUInteger idx, BOOL * _Nonnull stop) {
        DVBPostViewModel *vm = [[DVBPostViewModel alloc] initWithPost:post andIndex:idx];
        if (forAnswer) {
            [vm convertToNested];
        }
        [vmPosts addObject:vm];
    }];
    return [vmPosts copy];
}

#pragma mark - ASTableNode

- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBPostViewModel *post = _posts[indexPath.row];
    return ^{
        return [[DVBPostNode alloc] initWithPost:post andDelegate:self];
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
         _posts = [self convertPostsToViewModel:posts forAnswer:NO];
         dispatch_async(dispatch_get_main_queue(), ^{
             [_tableNode reloadData];
             [_refreshControl endRefreshing];
             // [_bottomRefreshControl endRefreshing];
             [self checkNewPostsCount];
             // self.tableView.backgroundView = nil;
         });

         _refreshControl.enabled = YES;
         // _bottomRefreshControl.enabled = YES;
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
    NSInteger lastRowIndex = [_tableNode numberOfRowsInSection:0] - 1;
    if (lastRowIndex < 0) {
        lastRowIndex = 0;
    }
    [_tableNode scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastRowIndex inSection:0]
                      atScrollPosition:UITableViewScrollPositionBottom
                              animated:YES];
}

#pragma mark - DVBThreadDelegate

- (void)openGalleryWIthUrl:(NSString *)url
{
    NSInteger thumbIndex = [_threadModel.thumbImagesArray indexOfObject:url];
    if (thumbIndex == NSNotFound) {
        return;
    }
    DVBMediaOpener *mediaOpener = [[DVBMediaOpener alloc] initWithViewController:self];

    [mediaOpener openMediaWithUrlString:_threadModel.fullImagesArray[thumbIndex]
                    andThumbImagesArray:_threadModel.thumbImagesArray
                     andFullImagesArray:_threadModel.fullImagesArray];
}

- (void)quotePostIndex:(NSInteger)index andText:(nullable NSString *)text
{
    [self attachAnswerToCommentWithPostIndex:index andText:text];
    
    if ([self shouldStopReplyAndRedirect]) {
        return;
    }
    
    [self composeAction];
}
- (void)showAnswersFor:(NSInteger)index
{
    DVBPost *post = _threadModel.postsArray[index];
    [DVBRouter pushAnswersFrom:self
                       postNum:post.num
                       answers:[self convertPostsToViewModel:post.replies forAnswer:YES]
                      allPosts:_allPosts ? _allPosts : _posts
     ];
}

- (void)attachAnswerToCommentWithPostIndex:(NSInteger)index andText:(nullable NSString *)text
{
    DVBPostViewModel *post = _posts[index];
    NSString *postNum = post.num;
    
    DVBComment *sharedComment = [DVBComment sharedComment];
    
    if (text) {
        NSAttributedString *postComment = post.text;
        [sharedComment topUpCommentWithPostNum:postNum
                           andOriginalPostText:postComment
                                andQuoteString:text];
    } else {
        [sharedComment topUpCommentWithPostNum:postNum];
    }
}

- (void)shareWithUrl:(NSString *)url
{
  UIBarButtonItem *shareItem = self.toolbarItems[4];
  [DVBThreadUIGenerator shareUrl:url
                          fromVC:self
                      fromButton:shareItem];
}

- (BOOL)isLinkInternalWithLink:(UrlNinja *)url
{
  UrlNinja *urlNinjaHelper = [[UrlNinja alloc] init];
  urlNinjaHelper.urlOpener = self;
  BOOL answer = [urlNinjaHelper isLinkInternalWithLink:url andThreadNum:_threadModel.threadNum andBoardCode:_threadModel.boardCode];

  return answer;
}

- (void)openPostWithUrlNinja:(UrlNinja *)urlNinja
{
  NSString *postNum = urlNinja.postId;
  NSPredicate *postNumPredicate = [NSPredicate predicateWithFormat:@"num == %@", postNum];

  NSArray *arrayOfPosts = [_threadModel.postsArray filteredArrayUsingPredicate:postNumPredicate];

  DVBPost *post;

  if ([arrayOfPosts count] > 0) { // check our regular array first
    post = arrayOfPosts[0];
    [DVBRouter pushAnswersFrom:self
                       postNum:post.num
                       answers:[self convertPostsToViewModel:@[post] forAnswer:YES]
                      allPosts:_allPosts ? _allPosts : _posts
     ];
    return;
  }
  else if (_allPosts) { // if it didn't work - check our full array
    arrayOfPosts = [_allPosts filteredArrayUsingPredicate:postNumPredicate];

    if ([arrayOfPosts count] > 0) {
      post = arrayOfPosts[0];
      DVBPostViewModel *postVM = (DVBPostViewModel *)post;
      [postVM convertToNested];
      [DVBRouter pushAnswersFrom:self
                         postNum:postVM.num
                         answers:@[postVM]
                        allPosts:_allPosts ? _allPosts : _posts
       ];
    }
    else { // end method if we can't find posts
      return;
    }
  }
  else { // if we do not have allThreadsArray AND can't find post in regular array (impossible but just in case...)
    return;
  }

}

- (void)openThreadWithUrlNinja:(UrlNinja *)urlNinja
{
  [DVBRouter pushThreadFrom:self
                      board:urlNinja.boardId
                     thread:urlNinja.threadId
                    subject:nil
                    comment:nil];
}

#pragma mark - DVBCreatePostViewControllerDelegate

-(void)updateThreadAfterPosting
{
  [self reloadThread];
}

#pragma mark - Helpers for posting from another copy of the controller

/// Plain post id reply
- (BOOL)shouldStopReplyAndRedirect
{
    if ([self shouldPopToPreviousControllerBeforeAnswering]) {
        DVBAsyncThreadViewController *firstThreadVC = self.navigationController.viewControllers[2];
        [self.navigationController popToViewController:firstThreadVC
                                              animated:YES];
        [DVBRouter showComposeFrom:firstThreadVC boardCode:_threadModel.boardCode threadNum:_threadModel.threadNum];
        return true;
    }
    
    return false;
}

/// Helper to determine if current controller is the original one or just 'Answers' controller
- (BOOL)shouldPopToPreviousControllerBeforeAnswering
{
    NSArray *arrayOfControllers = self.navigationController.viewControllers;
    
    NSInteger countOfThreadControllersInStack = 0;
    for (UIViewController *vc in arrayOfControllers) {
        if ([vc isKindOfClass:self.class]) {
            countOfThreadControllersInStack++;
            
            if ((countOfThreadControllersInStack >= 2)&&
                (self.navigationController.viewControllers.count >= 3))
            {
                return true;
            }
        }
    }
    return false;
}

#pragma mark - Actions

- (void)composeAction
{
    [DVBRouter showComposeFrom:self boardCode:_threadModel.boardCode threadNum:_threadModel.threadNum];
}

- (void)shareAction
{
  NSString *url = [[NSString alloc] initWithFormat:@"%@/%@/res/%@.html", [DVBUrls base], _threadModel.boardCode, _threadModel.threadNum];
  [self shareWithUrl:url];
}

- (void)flagAction
{
    weakify(self);
    [DVBThreadUIGenerator flagFromVC:self handler:^(UIAlertAction * _Nonnull action) {
        strongify(self);
        if (!self) { return; }
        [self.threadModel reportThread];
        [self showPromptAboutReportedPost];
    }];
}

- (void)bookmarkAction
{
    [_threadModel bookmarkThreadWithTitle:self.title];
    [self showPromptWithMessage:NSLS(@"PROMPT_THREAD_BOOKMARKED")];
}

- (void)showPromptAboutReportedPost
{
    self.navigationItem.prompt = NSLS(@"PROMPT_REPORT_SENT");
    [self performSelector:@selector(clearPrompt)
               withObject:nil
               afterDelay:2.0];
}

@end

NS_ASSUME_NONNULL_END
