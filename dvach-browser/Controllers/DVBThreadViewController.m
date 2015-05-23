//
//  DVBThreadViewController.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 11/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <UINavigationItem+Loading.h>
#import <TUSafariActivity/TUSafariActivity.h>

#import "DVBConstants.h"
#import "Reachlibility.h"
#import "DVBThreadModel.h"
#import "DVBNetworking.h"
#import "DVBComment.h"
#import "DVBAlertViewGenerator.h"
#import "DVBMediaOpener.h"
#import "DVBThreadControllerTableViewManager.h"

#import "DVBThreadViewController.h"
#import "DVBCreatePostViewController.h"
#import "DVBBrowserViewControllerBuilder.h"

#import "ARChromeActivity.h"

static CGFloat const MAX_OFFSET_DIFFERENCE_TO_SCROLL_AFTER_POSTING = 500.0f;

@interface DVBThreadViewController () <UIActionSheetDelegate, DVBCreatePostViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *shareButton;
@property (nonatomic, strong) DVBThreadControllerTableViewManager *threadControllerTableViewManager;

/// Model for posts in the thread
@property (nonatomic, strong) DVBThreadModel *threadModel;

/// Action sheet for reporting bad threads
@property (nonatomic, strong) UIActionSheet *reportSheet;
@property (nonatomic, assign) NSUInteger updatedTimes;
@property (nonatomic, assign) BOOL presentedSomething;
/// New posts count added with last thread update
@property (nonatomic, strong) NSNumber *previousPostsCount;

@end

@implementation DVBThreadViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (_autoScrollTo && !_presentedSomething) {
        CGFloat scrollToOffset = [_autoScrollTo floatValue];
        [self.tableView setContentOffset:CGPointMake(0, scrollToOffset)
                                animated:NO];
    }
    else {
        _presentedSomething = NO;
    }

    [self toolbarHandler];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    BOOL isIOSgreater80 = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0");
    BOOL isIOSlessTHAN83 = SYSTEM_VERSION_LESS_THAN(@"8.3");

    // This preventing table view from jumping when we push other controller (answers/ gallery on top of it) in iOS 8.1-8.2
    if (isIOSgreater80 && isIOSlessTHAN83) {
        [self.tableView reloadData];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prepareViewController];
    [self reloadThread];
}

- (void)toolbarHandler
{
    if (_answersToPost) {
        [self.navigationController setToolbarHidden:YES animated:NO];
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
    else {
        [self.navigationController setToolbarHidden:NO animated:NO];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
}

- (void)prepareViewController
{
    _threadControllerTableViewManager = [[DVBThreadControllerTableViewManager alloc] initWith:self];
    self.tableView.delegate = _threadControllerTableViewManager;
    self.tableView.dataSource = _threadControllerTableViewManager;

    if (_answersToPost) {

        _threadControllerTableViewManager.answersToPost = _answersToPost;

        // Disable refresh controll for answers VC (because we have nothing to refresh
        self.refreshControl = nil;

        if (!_postNum) {
            @throw [NSException exceptionWithName:@"No post number specified for answers" reason:@"Please, set postNum to show in title of the VC" userInfo:nil];
        }
        else {
            NSString *answerTitle;

            if (_isItPostItself) {
                answerTitle = @"";
            }
            else {
                answerTitle = NSLocalizedString(@"Ответы к", @"ThreadVC title if we show answers for specific post");
            }
            self.title = [NSString stringWithFormat:@"%@ %@", answerTitle, _postNum];
        }

        _threadModel = [[DVBThreadModel alloc] init];
        
        NSArray *arrayOfThumbs = [_threadModel thumbImagesArrayForPostsArray:_answersToPost];
        _threadControllerTableViewManager.thumbImagesArray = arrayOfThumbs;
        
        NSArray *arrayOfFullImages = [_threadModel fullImagesArrayForPostsArray:_answersToPost];
        _threadControllerTableViewManager.fullImagesArray = arrayOfFullImages;
    }
    else {
        [self.navigationController setToolbarHidden:NO animated:NO];
        [self.navigationItem startAnimatingAt:ANNavBarLoaderPositionRight];
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

/// Allocating refresh controll - for fetching new updated result from server by pulling board table view down.
- (void)makeRefreshAvailable
{
    // Top refresh
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(reloadThread)
                  forControlEvents:UIControlEventValueChanged];
}

#pragma mark - Links

- (BOOL)isLinkInternalWithLink:(UrlNinja *)url
{
    UrlNinja *urlNinjaHelper = [[UrlNinja alloc] init];

    __weak __typeof__(self) weakSelf = self;
    urlNinjaHelper.urlOpener = weakSelf;

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

/// Clear prompt from any status / error messages.
- (void)clearPrompt
{
    self.navigationItem.prompt = nil;
}

#pragma mark - Data management and processing

/// Get data from 2ch server
- (void)getPostsWithBoard:(NSString *)board andThread:(NSString *)threadNum andCompletion:(void (^)(NSArray *))completion
{
    [_threadModel reloadThreadWithCompletion:^(NSArray *completionsPosts) {
        _threadControllerTableViewManager.postsArray = _threadModel.postsArray;
        _threadControllerTableViewManager.thumbImagesArray = _threadModel.thumbImagesArray;
        _threadControllerTableViewManager.fullImagesArray = _threadModel.fullImagesArray;
        completion(completionsPosts);
    }];
}

/// Reload thread by current thread num
- (void)reloadThread {

    if (_answersToPost) {
        _threadControllerTableViewManager.postsArray = [_answersToPost mutableCopy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
    else {
        [self getPostsWithBoard:_boardCode
                      andThread:_threadNum
                  andCompletion:^(NSArray *postsArrayBlock)
        {
            _threadControllerTableViewManager.postsArray = postsArrayBlock;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self.refreshControl endRefreshing];
                [self checkNewPostsCount];
            });
        }];
    }
}

#pragma mark - Actions from Storyboard

- (IBAction)reloadThreadAction:(id)sender
{
    [self.navigationItem startAnimatingAt:ANNavBarLoaderPositionRight];
    [self reloadThread];
}

- (IBAction)scrollToBottom:(id)sender
{
    [self scrollToBottom];
}

- (IBAction)shareAction:(id)sender
{
    NSString *urlToShare = [[NSString alloc] initWithFormat:@"%@%@/res/%@.html", DVACH_BASE_URL, _boardCode, _threadNum];
    [self callShareControllerWithUrlString:urlToShare];
}

- (IBAction)reportAction:(id)sender
{
    NSString *cancelButtonTitle = NSLocalizedString(@"Отмена", @"Кнопка Отмена");
    NSString *destructiveButtonTitle = NSLocalizedString(@"Пожаловаться", @"Кнопка Пожаловаться");
    _reportSheet = [[UIActionSheet alloc] initWithTitle:nil
                                               delegate:self
                                      cancelButtonTitle:cancelButtonTitle
                                 destructiveButtonTitle:destructiveButtonTitle
                                      otherButtonTitles:nil];

    [_reportSheet showInView:self.tableView];
}

- (IBAction)answerToPost:(id)sender
{
    UIButton *pressedButton = (UIButton *)sender;
    NSUInteger indexForObject = pressedButton.tag;

    DVBComment *sharedComment = [DVBComment sharedComment];

    DVBPost *post = [_threadControllerTableViewManager.postsArray objectAtIndex:indexForObject];
    NSString *postNum = post.num;

    [sharedComment topUpCommentWithPostNum:postNum];

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [self performSegueWithIdentifier:SEGUE_TO_NEW_POST
                                  sender:self];
    }
    else {
        [self performSegueWithIdentifier:SEGUE_TO_NEW_POST_IOS_7
                                  sender:self];
    }
}

- (IBAction)answerToPostWithQuote:(id)sender
{
    UIButton *pressedButton = (UIButton *)sender;
    NSUInteger indexForObject = pressedButton.tag;

    DVBComment *sharedComment = [DVBComment sharedComment];

    DVBPost *post = [_threadControllerTableViewManager.postsArray objectAtIndex:indexForObject];
    NSString *postNum = post.num;
    NSAttributedString *postComment = post.comment;

    [sharedComment topUpCommentWithPostNum:postNum
                       andOriginalPostText:postComment
                            andQuoteString:_quoteString];
    _quoteString = @"";

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [self performSegueWithIdentifier:SEGUE_TO_NEW_POST
                                  sender:self];
    }
    else {
        [self performSegueWithIdentifier:SEGUE_TO_NEW_POST_IOS_7
                                  sender:self];
    }
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
    }
    else { // if we haven't - create it from current posts array (because postsArray is fullPostsArray in this iteration)
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
    if ([[segue identifier] isEqualToString:SEGUE_TO_NEW_POST] || [[segue identifier] isEqualToString:SEGUE_TO_NEW_POST_IOS_7]) {
        DVBCreatePostViewController *createPostViewController = (DVBCreatePostViewController*) [[segue destinationViewController] topViewController];
        
        createPostViewController.threadNum = _threadNum;
        createPostViewController.boardCode = _boardCode;
        createPostViewController.createPostViewControllerDelegate = self;
    }
}

// We need to twick our segues a little because of difference between iOS 7 and iOS 8 in segue types
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // if we have Device with version under 8.0
    if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {

        // and we have fancy popover 8.0 segue
        if ([identifier isEqualToString:SEGUE_TO_NEW_POST]) {

            // Execute iOS 7 segue
            [self performSegueWithIdentifier:SEGUE_TO_NEW_POST_IOS_7 sender:self];

            // drop iOS 8 segue
            return NO;
        }

        return YES;
    }
    
    return YES;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ((actionSheet == _reportSheet) && (buttonIndex == 0)) {
        [_threadModel reportThreadWithBoardCode:_boardCode
                                      andThread:_threadNum
                                     andComment:@"нарушение правил"];
        [self showPromptAboutReportedPost];
    }
}

#pragma mark - UIActivityViewController

- (void)callShareControllerWithUrlString:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSArray *objectsToShare = @[url];

    TUSafariActivity *safariAtivity = [[TUSafariActivity alloc] init];

    ARChromeActivity *chromeActivity = [[ARChromeActivity alloc] init];

    NSString *openInChromActivityTitle = NSLocalizedString(@"Открыть в Chrome", @"Title of the open in chrome share activity.");

    [chromeActivity setActivityTitle:openInChromActivityTitle];

    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:@[safariAtivity, chromeActivity]];

    // Only for iOS 8
    if ( [activityViewController respondsToSelector:@selector(popoverPresentationController)] ) {
        activityViewController.popoverPresentationController.barButtonItem = _shareButton;
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
    DVBComment *comment = [DVBComment sharedComment];

    if (comment.createdPost) {
        [self.tableView beginUpdates];

        NSMutableArray *postsArrayMutable = [_threadControllerTableViewManager.postsArray mutableCopy];
        NSUInteger newSectionIndex = _threadControllerTableViewManager.postsArray.count;
        [postsArrayMutable addObject:comment.createdPost];
        _threadControllerTableViewManager.postsArray = [postsArrayMutable copy];
        postsArrayMutable = nil;

        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:newSectionIndex] withRowAnimation:UITableViewRowAnimationRight];

        [self.tableView endUpdates];
        comment.createdPost = nil;

        // Check if difference is not too big (scroll isn't needed if user saw only half of the thread)
        CGFloat offsetDifference = self.tableView.contentSize.height - self.tableView.contentOffset.y - self.tableView.bounds.size.height;

        if (offsetDifference < MAX_OFFSET_DIFFERENCE_TO_SCROLL_AFTER_POSTING) {
            [NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(scrollToBottom)
                                           userInfo:nil
                                            repeats:NO];
        }
    }
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
    NSString *complaintSentPrompt = NSLocalizedString(@"Жалоба отправлена", @"Prompt сообщает о том, что жалоба отправлена.");
    self.navigationItem.prompt = complaintSentPrompt;
    [self performSelector:@selector(clearPrompt)
               withObject:nil
               afterDelay:2.0];
}

#pragma mark - New posts count handling

/// Check if server have new posts and scroll if user already scrolled to the end
- (void)checkNewPostsCount
{
    NSInteger additionalPostCount = [_threadControllerTableViewManager.postsArray count] - [_previousPostsCount integerValue];

    CGFloat stopAnimateTimerInterval = 0.5;

    if (([_previousPostsCount integerValue] > 0) && (additionalPostCount > 0)) {
        self.navigationItem.prompt = [NSString stringWithFormat:@"%ld %@", (long)additionalPostCount, @"новых"];
        [self performSelector:@selector(clearPrompt)
                   withObject:nil
                   afterDelay:1.5];

        // Check if difference is not too big (scroll isn't needed if user saw only half of the thread)
        CGFloat offsetDifference = self.tableView.contentSize.height - self.tableView.contentOffset.y - self.tableView.bounds.size.height;

        if (offsetDifference < MAX_OFFSET_DIFFERENCE_TO_SCROLL_AFTER_POSTING) {
            [NSTimer scheduledTimerWithTimeInterval:2.0
                                             target:self
                                           selector:@selector(scrollToBottom)
                                           userInfo:nil
                                            repeats:NO];
        }

        stopAnimateTimerInterval = 2.0;
    }

    NSNumber *postsCountNewValue = [NSNumber numberWithInteger:[_threadControllerTableViewManager.postsArray count]];

    _threadsScrollPositionManager.threadPostCounts[_threadNum] = postsCountNewValue;
    _previousPostsCount = postsCountNewValue;

    [NSTimer scheduledTimerWithTimeInterval:stopAnimateTimerInterval
                                     target:self
                                   selector:@selector(stopAnimateLoading)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)stopAnimateLoading
{
    [self.navigationItem stopAnimating];
}

@end
