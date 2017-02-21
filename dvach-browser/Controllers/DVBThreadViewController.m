//
//  DVBThreadViewController.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 11/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <SDWebImage/SDWebImageManager.h>
#import <TUSafariActivity/TUSafariActivity.h>
#import <CCBottomRefreshControl/UIScrollView+BottomRefreshControl.h>
#import <Reachability/Reachability.h>

#import "DVBThreadViewController.h"
#import "DVBCreatePostViewController.h"
#import "DVBBrowserViewControllerBuilder.h"

#import "ARChromeActivity.h"

static CGFloat const MAX_OFFSET_DIFFERENCE_TO_SCROLL_AFTER_POSTING = 500.0f;

@interface DVBCommonTableViewController ()

- (void)showMessageAboutDataLoading;
- (void)showMessageAboutError;

@end

@interface DVBThreadViewController () <UIActionSheetDelegate, DVBCreatePostViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *shareButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *refreshButton;

@property (nonatomic, strong) DVBThreadControllerTableViewManager *threadControllerTableViewManager;

/// Model for posts in the thread
@property (nonatomic, strong) DVBThreadModel *threadModel;

/// Action sheet for reporting bad threads
@property (nonatomic, strong) UIActionSheet *reportSheet;
@property (nonatomic, assign) NSUInteger updatedTimes;
@property (nonatomic, assign) BOOL presentedSomething;
/// New posts count added with last thread update
@property (nonatomic, strong) NSNumber *previousPostsCount;

@property (nonatomic, strong, nullable) UIRefreshControl *bottomRefreshControl;

@end

@implementation DVBThreadViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (_autoScrollTo && !_presentedSomething) {
        CGFloat scrollToOffset = [_autoScrollTo floatValue];
        [self.tableView setContentOffset:CGPointMake(0, scrollToOffset)
                                animated:NO];
    } else {
        _presentedSomething = NO;
    }

    [self toolbarHandler];

    [self makeBottomRefreshAvailable];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _bottomRefreshControl = nil;
    self.tableView.bottomRefreshControl = nil;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self darkThemeHandler];
    [self prepareViewController];

    if (_answersToPost) {
        [self reloadThread];
    } else {
        [self initialThreadLoad];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)darkThemeHandler
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        self.tableView.backgroundColor = [UIColor blackColor];
        self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
    } else {
        self.tableView.backgroundColor = [UIColor whiteColor];
        self.navigationController.toolbar.barStyle = UIBarStyleDefault;
    }
}

- (void)toolbarHandler
{
    if (_answersToPost) {
        [self.navigationController setToolbarHidden:YES animated:NO];
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    } else {
        [self.navigationController setToolbarHidden:NO animated:NO];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
}

- (void)prepareViewController
{
    _threadControllerTableViewManager = [[DVBThreadControllerTableViewManager alloc] initWith:self];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.delegate = _threadControllerTableViewManager;
    self.tableView.dataSource = _threadControllerTableViewManager;

    if (_answersToPost) {

        _threadControllerTableViewManager.answersToPost = _answersToPost;

        // Disable refresh controll for answers VC (because we have nothing to refresh
        self.refreshControl = nil;

        if (!_postNum) {
            @throw [NSException exceptionWithName:@"No post number specified for answers" reason:@"Please, set postNum to show in title of the VC" userInfo:nil];
        } else {
            NSString *answerTitle;

            if (_isItPostItself) {
                answerTitle = @"";
            }
            else {
                answerTitle = NSLS(@"TITLE_ANSWERS_TO");
            }
            self.title = [NSString stringWithFormat:@"%@ %@", answerTitle, _postNum];
        }

        _threadModel = [[DVBThreadModel alloc] init];
        
        NSArray *arrayOfThumbs = [_threadModel thumbImagesArrayForPostsArray:_answersToPost];
        _threadControllerTableViewManager.thumbImagesArray = arrayOfThumbs;
        
        NSArray *arrayOfFullImages = [_threadModel fullImagesArrayForPostsArray:_answersToPost];
        _threadControllerTableViewManager.fullImagesArray = arrayOfFullImages;
    } else {
        [self.navigationController setToolbarHidden:NO animated:NO];

        // Disable refresh button
        _refreshButton.enabled = NO;

        // Set view controller title depending on...
        self.title = [self getSubjectOrNumWithSubject:_threadSubject
                                         andThreadNum:_threadNum];
        _threadModel = [[DVBThreadModel alloc] initWithBoardCode:_boardCode
                                                    andThreadNum:_threadNum];

        _threadsScrollPositionManager = [DVBThreadsScrollPositionManager sharedThreads];

        _topBarDifference = 0;

        if ([_threadsScrollPositionManager.threads objectForKey:_threadNum]) {
            _autoScrollTo = [_threadsScrollPositionManager.threads objectForKey:_threadNum];
        }
        else {
            NSNumber *initialScrollValue = [NSNumber numberWithFloat:self.tableView.contentOffset.y];
            [_threadsScrollPositionManager.threads setValue:initialScrollValue
                                                     forKey:_threadNum];
        }

        if (_threadsScrollPositionManager.threadPostCounts[_threadNum]) {
            _previousPostsCount = _threadsScrollPositionManager.threadPostCounts[_threadNum];
        }
        else {
            _previousPostsCount = 0;
        }

        [self makeRefreshAvailable];
    }
}

#pragma mark - Set titles and gestures

- (NSString *)getSubjectOrNumWithSubject:(NSString *)subject andThreadNum:(NSString *)num
{
    /// If thread Subject is empty - return OP post number
    BOOL isSubjectEmpty = [subject isEqualToString:@""];
    if (isSubjectEmpty) {
        return num;
    }
    
    return subject;
}

#pragma mark - Refresh

/// Allocating top refresh controll - for fetching new updated result from server by pulling board table view down.
- (void)makeRefreshAvailable
{
    // Top refresh
    [self.refreshControl addTarget:self
                            action:@selector(reloadThread)
                  forControlEvents:UIControlEventValueChanged];
    self.refreshControl.enabled = YES;
}

/// Allocating bottom refresh controll - for fetching new updated result from server by pulling board table view down.
- (void)makeBottomRefreshAvailable
{
    if (!_answersToPost) {
        _bottomRefreshControl = [UIRefreshControl new];
        _bottomRefreshControl.triggerVerticalOffset = 80.;
        [_bottomRefreshControl addTarget:self action:@selector(reloadThread) forControlEvents:UIControlEventValueChanged];
        self.tableView.bottomRefreshControl = _bottomRefreshControl;
    }
}

#pragma mark - Links

- (BOOL)isLinkInternalWithLink:(UrlNinja *)url
{
    UrlNinja *urlNinjaHelper = [[UrlNinja alloc] init];
    urlNinjaHelper.urlOpener = self;
    BOOL answer = [urlNinjaHelper isLinkInternalWithLink:url andThreadNum:_threadNum andBoardCode:_boardCode];

    return answer;
}

- (void)openPostWithUrlNinja:(UrlNinja *)urlNinja
{
    NSString *postNum = urlNinja.postId;
    
    NSPredicate *postNumPredicate = [NSPredicate predicateWithFormat:@"num == %@", postNum];
    
    NSArray *arrayOfPosts = [_threadControllerTableViewManager.postsArray filteredArrayUsingPredicate:postNumPredicate];

    DVBPost *post;
    
    if ([arrayOfPosts count] > 0) { // check our regular array first
        post = arrayOfPosts[0];
    }
    else if (_allThreadPosts) { // if it didn't work - check our full array
        arrayOfPosts = [_allThreadPosts filteredArrayUsingPredicate:postNumPredicate];

        if ([arrayOfPosts count] > 0) {
            post = arrayOfPosts[0];
        }
        else { // end method if we can't find posts
            return;
        }
    }
    else { // if we do not have allThreadsArray AND can't find post in regular array (impossible but just in case...)
        return;
    }
    
    DVBThreadViewController *threadViewController = [self.storyboard instantiateViewControllerWithIdentifier:STORYBOARD_ID_THREAD_VIEW_CONTROLLER];

    // because we need title to show us real current postNum - so if we open link from post - id from link need to be our new View Controller title
    threadViewController.postNum = post.num;
    threadViewController.answersToPost = @[post];
    threadViewController.isItPostItself = YES;

    // check if we have full array of posts
    if (_allThreadPosts) { // if we have - then just pass it further
        threadViewController.allThreadPosts = _allThreadPosts;
    }
    else { // if we haven't - create it from current posts array (because postsArray is fullPostsArray in this iteration)
        threadViewController.allThreadPosts = _threadControllerTableViewManager.postsArray;
    }
    _presentedSomething = YES;

    [self.navigationController pushViewController:threadViewController
                                         animated:YES];
}

- (void)openThreadWithUrlNinja:(UrlNinja *)urlNinja
{
    DVBThreadViewController *threadViewControllerToOpen = [self.storyboard instantiateViewControllerWithIdentifier:STORYBOARD_ID_THREAD_VIEW_CONTROLLER];
    threadViewControllerToOpen.boardCode = urlNinja.boardId;
    threadViewControllerToOpen.threadNum = urlNinja.threadId;

    _presentedSomething = YES;

    [self.navigationController pushViewController:threadViewControllerToOpen
                                         animated:YES];
}

#pragma mark - Data management and processing

/// Get data for thread from Db if any
- (void)initialThreadLoad
{
    weakify(self);
    [_threadModel checkPostsInDbForThisThreadWithCompletion:^(NSArray *posts) {
        strongify(self);
        if (!self) { return; }
        self.threadControllerTableViewManager.postsArray = self.threadModel.postsArray;
        self.threadControllerTableViewManager.thumbImagesArray = self.threadModel.thumbImagesArray;
        self.threadControllerTableViewManager.fullImagesArray = self.threadModel.fullImagesArray;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        [self reloadThread];
    }];
}

/// Get data from 2ch server
- (void)getPostsWithBoard:(NSString *)board andThread:(NSString *)threadNum andCompletion:(void (^)(NSArray *))completion
{
    weakify(self);
    [_threadModel reloadThreadWithCompletion:^(NSArray *completionsPosts) {
        strongify(self);
        if (!self) { return; }
        self.threadControllerTableViewManager.postsArray = self.threadModel.postsArray;
        self.threadControllerTableViewManager.thumbImagesArray = self.threadModel.thumbImagesArray;
        self.threadControllerTableViewManager.fullImagesArray = self.threadModel.fullImagesArray;
        completion(completionsPosts);
    }];
}

/// Reload thread by current thread num
- (void)reloadThread
{
    if (!_answersToPost && ![_threadModel isConnectionAvailable]) {
        [self.refreshControl endRefreshing];
        [_bottomRefreshControl endRefreshing];
        return;
    }
    // Very stupid but necessary check.
    // So app can't double refresh the same thread at the same time
    if (!_answersToPost) {
        if (self.refreshControl.enabled) {
            if (self.refreshControl) {
                self.refreshControl.enabled = NO;
            }
            if (_bottomRefreshControl) {
                _bottomRefreshControl.enabled = NO;
            }
        } else {
            return;
        }
    }
    _refreshButton.enabled = NO;

    if (_answersToPost) {
        _threadControllerTableViewManager.postsArray = [_answersToPost mutableCopy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    } else {
        weakify(self);
        [self getPostsWithBoard:_boardCode
                      andThread:_threadNum
                  andCompletion:^(NSArray *postsArrayBlock)
        {
            strongify(self);
            if (!self) { return; }
            if (postsArrayBlock) {
                self.threadControllerTableViewManager.postsArray = postsArrayBlock;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    [self.refreshControl endRefreshing];
                    [self.bottomRefreshControl endRefreshing];
                    [self checkNewPostsCount];
                    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
                    self.tableView.backgroundView = nil;
                });
            } else {
                [self showMessageAboutError];
            }

            self.refreshControl.enabled = YES;
            self.bottomRefreshControl.enabled = YES;
        }];
    }
}

#pragma mark - Post 'n' shit

- (void)openPostingControllerFromThisOne
{
    [self performSegueWithIdentifier:SEGUE_TO_NEW_POST
                              sender:self];
}

- (void)attachAnswerToCommentSingletonWithPostIndex:(NSInteger)postIndex andTextToo:(BOOL)textToo
{
    DVBPost *post = _threadControllerTableViewManager.postsArray[postIndex];
    NSString *postNum = post.num;

    DVBComment *sharedComment = [DVBComment sharedComment];

    if (textToo) {
        NSAttributedString *postComment = post.comment;
        [sharedComment topUpCommentWithPostNum:postNum
                           andOriginalPostText:postComment
                                andQuoteString:_quoteString];
        _quoteString = @"";
    } else {
        [sharedComment topUpCommentWithPostNum:postNum];
    }
}

#pragma mark - Helpers for posting from another copy of the controller

/// Plain post id reply
- (BOOL)shouldStopReplyAndRedirectWithSender:(id)sender
{
    if ([self shouldPopToPreviousControllerBeforeAnsweringWithSender:sender]) {
        DVBThreadViewController *firstThreadVC = self.navigationController.viewControllers[2];
        [self.navigationController popToViewController:firstThreadVC
                                              animated:YES];
        [firstThreadVC openPostingControllerFromThisOne];
        return true;
    }

    return false;
}

/// Quote with text
- (BOOL)shouldStopReplyQuotingAndRedirectWithSender:(id)sender
{
    if ([self shouldPopToPreviousControllerBeforeAnsweringWithSender:sender]) {
        DVBThreadViewController *firstThreadVC = self.navigationController.viewControllers[2];
        [self.navigationController popToViewController:firstThreadVC
                                              animated:YES];
        [firstThreadVC openPostingControllerFromThisOne];
        return true;
    }

    return false;
}

/// Helper to determine if current controller is the original one or just 'Answers' controller
- (BOOL)shouldPopToPreviousControllerBeforeAnsweringWithSender:(id)sender
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

#pragma mark - Actions from Storyboard

- (IBAction)reloadThreadAction:(id)sender
{
    _refreshButton.enabled = NO;
    
    [self reloadThread];
}

- (IBAction)scrollToBottom:(id)sender
{
    [self scrollToBottom];
}

- (IBAction)bookmarkAction:(id)sender
{
    NSString *urlToShare = [[NSString alloc] initWithFormat:@"/%@/res/%@.html", _boardCode, _threadNum];
    NSDictionary *userInfo = @
    {
        @"url" : urlToShare,
        @"title" : self.title ? self.title : _threadNum
    };

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NAME_BOOKMARK_THREAD
                                                        object:self
                                                      userInfo:userInfo];
    [self showPromptWithMessage:NSLS(@"PROMPT_THREAD_BOOKMARKED")];
}

- (IBAction)shareAction:(id)sender
{
    NSString *urlToShare = [[NSString alloc] initWithFormat:@"%@%@/res/%@.html", [DVBUrls base], _boardCode, _threadNum];
    [self callShareControllerWithUrlString:urlToShare];
}

- (IBAction)reportAction:(id)sender
{
    _reportSheet = [[UIActionSheet alloc] initWithTitle:nil
                                               delegate:self
                                      cancelButtonTitle:NSLS(@"BUTTON_CANCEL")
                                 destructiveButtonTitle:NSLS(@"BUTTON_REPORT")
                                      otherButtonTitles:nil];

    [_reportSheet showInView:self.tableView];
}

- (IBAction)answerToPost:(id)sender
{
    UIButton *pressedButton = (UIButton *)sender;
    NSUInteger indexForObject = pressedButton.tag;

    [self attachAnswerToCommentSingletonWithPostIndex:indexForObject
                                           andTextToo:NO];

    if ([self shouldStopReplyAndRedirectWithSender:sender]) {
        return;
    }

    [self openPostingControllerFromThisOne];
}

- (IBAction)answerToPostWithQuote:(id)sender
{
    UIButton *pressedButton = (UIButton *)sender;
    NSUInteger indexForObject = pressedButton.tag;

    [self attachAnswerToCommentSingletonWithPostIndex:indexForObject
                                           andTextToo:YES];

    //
    if ([self shouldStopReplyAndRedirectWithSender:sender]) {
        return;
    }

    [self openPostingControllerFromThisOne];
}

- (IBAction)showAnswers:(id)sender
{
    UIButton *answerButton = sender;
    NSUInteger buttonClickedIndex = answerButton.tag;
    DVBPost *post = _threadControllerTableViewManager.postsArray[buttonClickedIndex];
    DVBThreadViewController *threadViewController = [self.storyboard instantiateViewControllerWithIdentifier:STORYBOARD_ID_THREAD_VIEW_CONTROLLER];
    NSString *postNum = post.num;
    threadViewController.postNum = postNum;
    threadViewController.answersToPost = post.replies;

    // check if we have full array of posts
    if (_allThreadPosts) { // if we have - then just pass it further
        threadViewController.allThreadPosts = _allThreadPosts;
    } else { // if we haven't - create it from current posts array (because postsArray is fullPostsArray in this iteration)
        threadViewController.allThreadPosts = _threadControllerTableViewManager.postsArray;
    }

    _presentedSomething = YES;

    [self.navigationController pushViewController:threadViewController
                                         animated:YES];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    _presentedSomething = YES;
    if ([[segue identifier] isEqualToString:SEGUE_TO_NEW_POST] ||
        [[segue identifier] isEqualToString:SEGUE_TO_NEW_POST_IOS_7])
    {
        DVBCreatePostViewController *createPostViewController = (DVBCreatePostViewController*) [[segue destinationViewController] topViewController];
        
        createPostViewController.threadNum = _threadNum;
        createPostViewController.boardCode = _boardCode;
        createPostViewController.createPostViewControllerDelegate = self;

        // Fix ugly white popover arrow on Popover Controller when dark theme enabled
        if ([[segue identifier] isEqualToString:SEGUE_TO_NEW_POST] &&
            [[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME])
        {
            [segue destinationViewController].popoverPresentationController.backgroundColor = [UIColor blackColor];
        }
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ((actionSheet == _reportSheet) && (buttonIndex == 0)) {
//        [_threadModel reportThreadWithBoardCode:_boardCode
//                                      andThread:_threadNum
//                                     andComment:@"нарушение правил"];
        [self showPromptAboutReportedPost];
    }
}

#pragma mark - UIActivityViewController

- (void)callShareControllerWithUrlString:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSArray *objectsToShare = @[url];
    TUSafariActivity *safariActivity = [[TUSafariActivity alloc] init];
    ARChromeActivity *chromeActivity = [[ARChromeActivity alloc] init];
    NSString *openInChromActivityTitle = NSLS(@"ACTIVITY_OPEN_IN_CHROME");
    [chromeActivity setActivityTitle:openInChromActivityTitle];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:@[safariActivity, chromeActivity]];

    // Only for iPad
    if ( [activityViewController respondsToSelector:@selector(popoverPresentationController)] ) {
        if (self.navigationController.isToolbarHidden) {
            activityViewController.popoverPresentationController.sourceView = self.navigationController.navigationBar;
            activityViewController.popoverPresentationController.sourceRect = self.navigationController.navigationBar.frame;
        } else {
            activityViewController.popoverPresentationController.barButtonItem = _shareButton;
        }
    }

    [self presentViewController:activityViewController
                       animated:YES
                     completion:nil];
}

#pragma mark - Photo gallery

- (void)openMediaWithUrlString:(NSString *)fullUrlString
{
    _presentedSomething = YES;
    DVBMediaOpener *mediaOpener = [[DVBMediaOpener alloc] initWithViewController:self];
    [mediaOpener openMediaWithUrlString:fullUrlString
                    andThumbImagesArray:_threadControllerTableViewManager.thumbImagesArray
                     andFullImagesArray:_threadControllerTableViewManager.fullImagesArray];
}

#pragma mark - DVBCreatePostViewControllerDelegate

-(void)updateThreadAfterPosting
{
    [self reloadThread];
}

- (void)scrollToBottom
{
    CGFloat heightDifference = self.tableView.contentSize.height - self.tableView.frame.size.height + self.navigationController.toolbar.frame.size.height;

    CGPoint pointToScrollTo = CGPointMake(0, heightDifference);

    [self.tableView setContentOffset:pointToScrollTo
                            animated:YES];
}

#pragma mark - Bad posts reporting

- (void)showPromptAboutReportedPost
{
    self.navigationItem.prompt = NSLS(@"PROMPT_REPORT_SENT");
    [self performSelector:@selector(clearPrompt)
               withObject:nil
               afterDelay:2.0];
}

#pragma mark - New posts count handling

/// Check if server have new posts and scroll if user already scrolled to the end
- (void)checkNewPostsCount
{
    NSInteger additionalPostCount = _threadControllerTableViewManager.postsArray.count - _previousPostsCount.integerValue;

    if (([_previousPostsCount integerValue] > 0) &&
        (additionalPostCount > 0))
    {
        NSNumber *newMessagesCount = @(additionalPostCount);

        [self performSelector:@selector(newMessagesPromptWithNewMessagesCount:)
                   withObject:newMessagesCount
                   afterDelay:0.5];
    }

    NSNumber *postsCountNewValue = @(_threadControllerTableViewManager.postsArray.count);

    _threadsScrollPositionManager.threadPostCounts[_threadNum] = postsCountNewValue;
    _previousPostsCount = postsCountNewValue;

    _refreshButton.enabled = YES;
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
    CGFloat offsetDifference = self.tableView.contentSize.height - self.tableView.contentOffset.y - self.tableView.bounds.size.height;

    if (offsetDifference < MAX_OFFSET_DIFFERENCE_TO_SCROLL_AFTER_POSTING &&
        _threadControllerTableViewManager.postsArray.count > 10) // Prevent scrolling when posts count isn't high enough
    {
        [NSTimer scheduledTimerWithTimeInterval:2.0
                                         target:self
                                       selector:@selector(scrollToBottom)
                                       userInfo:nil
                                        repeats:NO];
    }
}

- (void)showMessageAboutDataLoading
{
    [super showMessageAboutDataLoading];
}
- (void)showMessageAboutError
{
    [super showMessageAboutError];
}

@end
