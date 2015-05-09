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
#import "DVBPost.h"
#import "DVBComment.h"
#import "DVBAlertViewGenerator.h"
#import "DVBThreadsScrollPositionManager.h"

#import "DVBThreadViewController.h"
#import "DVBCreatePostViewController.h"
#import "DVBBrowserViewControllerBuilder.h"

#import "DVBMediaForPostTableViewCell.h"
#import "DVBPostTableViewCell.h"
#import "DVBActionsForPostTableViewCell.h"

#import "ARChromeActivity.h"

// Default row heights
static CGFloat const ROW_DEFAULT_HEIGHT = 75.0f;
static CGFloat const ROW_MEDIA_DEFAULT_HEIGHT = 75.0f;
static CGFloat const ROW_ACTIONS_DEFAULT_HEIGHT = 30.0f;

// thumbnail width in post row
static CGFloat const THUMBNAIL_WIDTH = 65.f;
// thumbnail contstraints for calculating layout dimentions
static CGFloat const HORISONTAL_CONSTRAINT = 10.0f; // we have 3 of them

/**
 *  Correction height because of:
 *  constraint from text to top - 10
 *  border - 1 more
 *  just in case I added 5 more :)
 */
static CGFloat const CORRECTION_HEIGHT_FOR_TEXT_VIEW_CALC = 17.0f;

static CGFloat const MAX_OFFSET_DIFFERENCE_TO_SCROLL_AFTER_POSTING = 500.0f;

@interface DVBThreadViewController () <UIActionSheetDelegate, DVBCreatePostViewControllerDelegate>

// Array of posts inside this thread
@property (nonatomic, strong) NSArray *postsArray;
// Model for posts in the thread
@property (nonatomic, strong) DVBThreadModel *threadModel;
// Array of all post thumb images in thread
@property (nonatomic, strong) NSArray *thumbImagesArray;
// Array of all post full images in thread
@property (nonatomic, strong) NSArray *fullImagesArray;
@property (nonatomic, strong) DVBPostTableViewCell *prototypeCell;
// Action sheet for displaying bad posts flaggind (and maybe somethig more later)
@property (nonatomic, strong) UIActionSheet *postLongPressSheet;
@property (nonatomic, strong) NSString *flaggedPostNum;
@property (nonatomic, assign) NSUInteger selectedWithLongPressSection;
@property (nonatomic, assign) NSUInteger updatedTimes;
// For marking if OP message already glagged or not (tech prop)
@property (nonatomic, assign) BOOL opAlreadyDeleted;
// iOS 8+ reference for iPad - to "give a birth" to popover share controller
@property (nonatomic, strong) UIButton *buttonToShowPopoverFrom;

// Auto scrolling stuff
@property (nonatomic, strong) DVBThreadsScrollPositionManager *threadsScrollPositionManager;
@property (nonatomic, strong) NSNumber *autoScrollTo;

@end

@implementation DVBThreadViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self rightBarButtonHandler];

    if (_autoScrollTo) {
        CGFloat scrollToOFfset = [_autoScrollTo floatValue];
        [self.tableView setContentOffset:CGPointMake(0, scrollToOFfset)
                                animated:NO];
    }
}

// This preventing table view from jumping when we push other controller (answers/ gallery on top of it).
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prepareViewController];
    [self reloadThread];
}

- (void)rightBarButtonHandler
{
    if (_answersToPost) {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
    else {
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
}

- (void)prepareViewController
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    _opAlreadyDeleted = NO;
    
    if (_answersToPost) {

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
        _thumbImagesArray = [arrayOfThumbs mutableCopy];
        
        NSArray *arrayOfFullImages = [_threadModel fullImagesArrayForPostsArray:_answersToPost];
        _fullImagesArray = [arrayOfFullImages mutableCopy];
    }
    else {
        [self.navigationItem startAnimatingAt:ANNavBarLoaderPositionRight];
        // Set view controller title depending on...
        self.title = [self getSubjectOrNumWithSubject:_threadSubject
                                         andThreadNum:_threadNum];
        _threadModel = [[DVBThreadModel alloc] initWithBoardCode:_boardCode
                                                    andThreadNum:_threadNum];

        _threadsScrollPositionManager = [DVBThreadsScrollPositionManager sharedThreads];

        if ([_threadsScrollPositionManager.threads objectForKey:_threadNum]) {
            _autoScrollTo = [_threadsScrollPositionManager.threads objectForKey:_threadNum];
        }
        else {
            NSNumber *initialScrollValue = [NSNumber numberWithFloat:self.tableView.contentOffset.y];
            [_threadsScrollPositionManager.threads setValue:initialScrollValue
                                                     forKey:_threadNum];
        }
    }
    
    // System do not spend resources on calculating row heights via heightForRowAtIndexPath.
    if (![self respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
        self.tableView.estimatedRowHeight = ROW_DEFAULT_HEIGHT; // Maybe we need to set it to less number or othervise scroll to bottom of the table View will be fatal
        self.tableView.rowHeight = UITableViewAutomaticDimension;
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

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_postsArray count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    DVBPost *postTmpObj = _postsArray[section];
    NSString *date = postTmpObj.date;
    
    // we increase number by one because sections start count from 0 and post counts on 2ch commonly start with 1
    NSInteger postNumToShow = section + 1;
    
    NSString *sectionTitle = [[NSString alloc] initWithFormat:@"#%ld  %@", (long)postNumToShow, date];
    
    return sectionTitle;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    DVBPost *post = _postsArray[section];

    // If post have more than one thumbnail
    if ([post.thumbPathesArray count] > 1) {
        return 3;
    }

    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    DVBPost *post = _postsArray[indexPath.section];
    NSUInteger row = indexPath.row;

    // If post have more than one thumbnail...
    if (([post.thumbPathesArray count] > 1)&&(row == 0)) {
        cell = (DVBMediaForPostTableViewCell *) [tableView dequeueReusableCellWithIdentifier:POST_CELL_MEDIA_IDENTIFIER
                                                                             forIndexPath:indexPath];
        [self configureMediaCell:cell
               forRowAtIndexPath:indexPath];

    }
    else if (([post.thumbPathesArray count] > 1)&&(row == 2)) { // If post have more than one
        cell = (DVBActionsForPostTableViewCell *) [tableView dequeueReusableCellWithIdentifier:POST_CELL_ACTIONS_IDENTIFIER
                                                                                  forIndexPath:indexPath];
        [self configureActionsCell:cell
                 forRowAtIndexPath:indexPath];
    }
    else if (([post.thumbPathesArray count] < 2)&&(row == 1)) { // If post have only one
        cell = (DVBActionsForPostTableViewCell *) [tableView dequeueReusableCellWithIdentifier:POST_CELL_ACTIONS_IDENTIFIER
                                                                                  forIndexPath:indexPath];
        [self configureActionsCell:cell
                 forRowAtIndexPath:indexPath];
    }
    else {
        cell = (DVBPostTableViewCell *) [tableView dequeueReusableCellWithIdentifier:POST_CELL_IDENTIFIER
                                                                     forIndexPath:indexPath];
        [self configureCell:cell
          forRowAtIndexPath:indexPath];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = indexPath.row;
    DVBPost *post = _postsArray[indexPath.section];

    if (([post.thumbPathesArray count] > 1)&&(row == 0)) { // If post have more than one thumbnail and this is first row
        return ROW_MEDIA_DEFAULT_HEIGHT;
    }
    else if (([post.thumbPathesArray count] > 1)&&(row == 2)) { // If post have more than one thumbnail and this is third row
        return ROW_ACTIONS_DEFAULT_HEIGHT;
    }
    else if (([post.thumbPathesArray count] < 2)&&(row == 1)) { // If post have only one thumbnail and this is second row
        return ROW_ACTIONS_DEFAULT_HEIGHT;
    }
    else {

        // I am using a helper method here to get the text at a given cell.
        NSAttributedString *text = [self getTextAtIndex:indexPath];
        
        // Getting the width/height needed by the dynamic text view.

        CGSize viewSize = self.tableView.bounds.size;
        NSInteger viewWidth = viewSize.width;
        
        // Set default difference (if we hve image in the cell).
        CGFloat widthDifferenceBecauseOfImageAndConstraints = THUMBNAIL_WIDTH + HORISONTAL_CONSTRAINT * 3;
        
        // Determine if we really have image in the cell.
        DVBPost *postObj = _postsArray[indexPath.section];
        NSString *thumbPath = postObj.thumbPath;
        
        // If not - then set the difference just to two constraints.
        if ([thumbPath isEqualToString:@""]) {
            widthDifferenceBecauseOfImageAndConstraints = HORISONTAL_CONSTRAINT * 2;
        }
        
        // Decrease window width value by taking off elements and contraints values
        CGFloat textViewWidth = viewWidth - widthDifferenceBecauseOfImageAndConstraints;

        // Return the size of the current row.
        CGFloat heightToReturn = [self heightForText:text
                                   constrainedToSize:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
        
        CGFloat heightForReturnWithCorrectionAndCeilf = ceilf(heightToReturn + CORRECTION_HEIGHT_FOR_TEXT_VIEW_CALC);
        
        if (heightToReturn < ROW_DEFAULT_HEIGHT) {

            if ([thumbPath isEqualToString:@""]) {
                return heightForReturnWithCorrectionAndCeilf;
            }
            
            return (ROW_DEFAULT_HEIGHT + 1);
        }

        // We should not return values greater than 2009
        if (heightForReturnWithCorrectionAndCeilf > 2008) {
            return 2008;
        }
        
        return heightForReturnWithCorrectionAndCeilf;
    }

    return 0;
}

#pragma mark - Scroll Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y > 100) {
        [_threadsScrollPositionManager.threads setValue:[NSNumber numberWithFloat:scrollView.contentOffset.y] forKey:_threadNum];
    }
}

#pragma mark - Links

// We do not need this because we set it in another place.
/*
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}
 */

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
    
    NSArray *arrayOfPosts = [_postsArray filteredArrayUsingPredicate:postNumPredicate];

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
        threadViewController.allThreadPosts = _postsArray;
    }

    [self.navigationController pushViewController:threadViewController animated:YES];
}

/// Clear prompt from any status / error messages.
- (void)clearPrompt
{
    self.navigationItem.prompt = nil;
}

#pragma mark - Cell configuration and calculation

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[DVBPostTableViewCell class]]) {
        DVBPostTableViewCell *confCell = (DVBPostTableViewCell *)cell;
        DVBPost *post = _postsArray[indexPath.section];
        
        NSString *thumbUrlString = post.thumbPath;
        NSString *fullUrlString = post.path;

        BOOL showVideoIcon = (post.mediaType == webm);

        confCell.threadViewController = self;
        
        [confCell prepareCellWithCommentText:post.comment
                       andPostThumbUrlString:thumbUrlString
                        andPostFullUrlString:fullUrlString
                            andShowVideoIcon:showVideoIcon];
    }
}

- (void)configureMediaCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[DVBMediaForPostTableViewCell class]]) {
        DVBMediaForPostTableViewCell *confCell = (DVBMediaForPostTableViewCell *)cell;
        DVBPost *post = _postsArray[indexPath.section];

        confCell.threadViewController = self;
        [confCell prepareCellWithThumbPathesArray:post.thumbPathesArray
                                   andPathesArray:post.pathesArray];
    }
}

- (void)configureActionsCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[DVBActionsForPostTableViewCell class]]) {
        DVBActionsForPostTableViewCell *confCell = (DVBActionsForPostTableViewCell *)cell;
        DVBPost *post = _postsArray[indexPath.section];

        NSUInteger indexForButton = indexPath.section;

        BOOL shouldDisableActionButton = NO;

        if (_answersToPost) {
            shouldDisableActionButton = YES;
        }

        [confCell prepareCellWithPostRepliesCount:[post.replies count]
                                         andIndex:indexForButton
                           andDisableActionButton:shouldDisableActionButton];
    }
}

/// Utility method for calculation how much space we need to fit that text. Calculation for texView height.
-(CGFloat)heightForText:(NSAttributedString *)text constrainedToSize:(CGSize)size
{
    CGRect frame = CGRectIntegral([text boundingRectWithSize:size
                                                     options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                     context:nil]);

    return frame.size.height;
}

/**
 *  Think of this as a source for the text to be rendered in the text view.
 *  I used a dictionary to map indexPath to some dynamically fetched text.
 */
- (NSAttributedString *)getTextAtIndex:(NSIndexPath *)indexPath
{
    
    NSUInteger tmpIndex = indexPath.section;
    DVBPost *tmpObj =  _postsArray[tmpIndex];
    NSAttributedString *tmpComment = tmpObj.comment;
    
    return tmpComment;
}

#pragma mark - Data management and processing

/**
 *  Get data from 2ch server
 *
 *  @param board      <#board description#>
 *  @param threadNum  <#threadNum description#>
 *  @param completion <#completion description#>
 */
- (void)getPostsWithBoard:(NSString *)board andThread:(NSString *)threadNum andCompletion:(void (^)(NSArray *))completion
{
    [_threadModel reloadThreadWithCompletion:^(NSArray *completionsPosts) {
        _postsArray = _threadModel.postsArray;
        _thumbImagesArray = _threadModel.thumbImagesArray;
        _fullImagesArray = _threadModel.fullImagesArray;
        completion(completionsPosts);
    }];
}

// Reload thread by current thread num
- (void)reloadThread {

    if (_answersToPost) {
        _postsArray = [_answersToPost mutableCopy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
    else {
        [self getPostsWithBoard:_boardCode
                      andThread:_threadNum
                  andCompletion:^(NSArray *postsArrayBlock)
        {
            _postsArray = [postsArrayBlock mutableCopy];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self.navigationItem stopAnimating];
            });
        }];
    }
}

#pragma mark - Actions from Storyboard

- (IBAction)reloadThreadAction:(id)sender
{
    [self reloadThread];
}

- (IBAction)showAnswers:(id)sender
{
    UIButton *answerButton = sender;
    NSUInteger buttonClickedIndex = answerButton.tag;
    DVBPost *post = _postsArray[buttonClickedIndex];
    DVBThreadViewController *threadViewController = [self.storyboard instantiateViewControllerWithIdentifier:STORYBOARD_ID_THREAD_VIEW_CONTROLLER];
    NSString *postNum = post.num;
    threadViewController.postNum = postNum;
    threadViewController.answersToPost = post.replies;

    // check if we have full array of posts
    if (_allThreadPosts) { // if we have - then just pass it further
        threadViewController.allThreadPosts = _allThreadPosts;
    }
    else { // if we haven't - create it from current posts array (because postsArray is fullPostsArray in this iteration)
        threadViewController.allThreadPosts = _postsArray;
    }

    [self.navigationController pushViewController:threadViewController
                                         animated:YES];
}

- (IBAction)showPostActions:(id)sender
{
    UIButton *answerButton = sender;

    // Need for iOS 8 - iPad
    _buttonToShowPopoverFrom = answerButton;

    NSUInteger buttonClickedIndex = answerButton.tag;
    DVBPost *post = _postsArray[buttonClickedIndex];
    // setting variable to bad post number (we'll use it soon)
    _flaggedPostNum = post.num;
    _selectedWithLongPressSection = buttonClickedIndex;
    _postLongPressSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                      delegate:self
                                             cancelButtonTitle:@"Отмена"
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:
                           @"Ответить",
                           @"Ответить с цитатой",
                           @"Поделиться",
                           @"Пожаловаться", nil];
    
    [_postLongPressSheet showInView:self.tableView];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
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

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet == _postLongPressSheet) {

        switch (buttonIndex) {
                
            case 0: // add post answer to comment and make segue
            {
                DVBComment *sharedComment = [DVBComment sharedComment];

                DVBPost *post = [_postsArray objectAtIndex:_selectedWithLongPressSection];
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

                break;
            }

            case 1: // answer with quote
            {
                DVBComment *sharedComment = [DVBComment sharedComment];

                DVBPost *post = [_postsArray objectAtIndex:_selectedWithLongPressSection];
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

                break;
            }

            case 2: // Share
            {
                NSString *urlToShare = [[NSString alloc] initWithFormat:@"%@%@/res/%@.html", DVACH_BASE_URL, _boardCode, _threadNum];
                [self callShareControllerWithUrlString:urlToShare];
                break;
            }
                
            case 3: // Report button
            {
                [_threadModel reportThreadWithBoardCode:_boardCode andThread:_threadNum andComment:@"нарушение правил"];

                [self showPromptAboutReportedPost];
                break;
            }
            default:
            {
                break;
            }
        }
    }
}

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
        if (_buttonToShowPopoverFrom) {
            activityViewController.popoverPresentationController.sourceView = _buttonToShowPopoverFrom;
            activityViewController.popoverPresentationController.sourceRect = _buttonToShowPopoverFrom.bounds;
        }
        else {
            activityViewController.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
        }
    }

    [self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - Photo gallery

- (void)openMediaWithUrlString:(NSString *)fullUrlString
{
    // Check if cell have real image / webm video or just placeholder
    if (![fullUrlString isEqualToString:@""]) {
        // if contains .webm
        if ([fullUrlString rangeOfString:@".webm" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            NSURL *fullUrl = [NSURL URLWithString:fullUrlString];
            BOOL canOpenInVLC = [[UIApplication sharedApplication] canOpenURL:fullUrl];

            if (canOpenInVLC) {
                [[UIApplication sharedApplication] openURL:fullUrl];
            }
            else {
                NSString *installVLCPrompt = NSLocalizedString(@"Для просмотра установите VLC", @"Prompt in navigation bar of a thread View Controller - shows after user tap on the video and if user do not have VLC on the device");
                self.navigationItem.prompt = installVLCPrompt;
                [self performSelector:@selector(clearPrompt)
                           withObject:nil
                           afterDelay:2.0];
            }
        }
        // if not
        else {
            [self createAndPushGalleryWithUrlString:fullUrlString];
        }
    }
}

- (void)createAndPushGalleryWithUrlString:(NSString *)urlString
{
    NSUInteger indexForImageShowing = [_fullImagesArray indexOfObject:urlString];

    if (indexForImageShowing < [_fullImagesArray count]) {

        DVBBrowserViewControllerBuilder *galleryBrowser = [[DVBBrowserViewControllerBuilder alloc] initWithDelegate:nil];

        [galleryBrowser prepareWithIndex:indexForImageShowing
                     andThumbImagesArray:_thumbImagesArray
                      andFullImagesArray:_fullImagesArray];

        [self.navigationController pushViewController:galleryBrowser animated:YES];
    }
}

#pragma mark - DVBCreatePostViewControllerDelegate

-(void)updateThreadAfterPosting
{
    DVBComment *comment = [DVBComment sharedComment];

    if (comment.createdPost) {
        [self.tableView beginUpdates];

        NSMutableArray *postsArrayMutable = [_postsArray mutableCopy];
        NSUInteger newSectionIndex = _postsArray.count;
        [postsArrayMutable addObject:comment.createdPost];
        _postsArray = [postsArrayMutable copy];
        postsArrayMutable = nil;

        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:newSectionIndex] withRowAnimation:UITableViewRowAnimationRight];

        [self.tableView endUpdates];
        comment.createdPost = nil;

        [NSTimer scheduledTimerWithTimeInterval:0.7
                                         target:self
                                       selector:@selector(scrollToBottom)
                                       userInfo:nil
                                        repeats:NO];
    }
}

#pragma mark - Timer methods

- (void)scrollToBottom
{
    CGFloat yOffset = 0;

    if (self.tableView.contentSize.height > self.tableView.bounds.size.height) {
        yOffset = self.tableView.contentSize.height - self.tableView.bounds.size.height;
    }

    CGFloat offsetDifference = self.tableView.contentSize.height - self.tableView.contentOffset.y - self.tableView.bounds.size.height;

    if (offsetDifference < MAX_OFFSET_DIFFERENCE_TO_SCROLL_AFTER_POSTING) {
        [self.tableView setContentOffset:CGPointMake(0, yOffset) animated:NO];
    }
}

#pragma mark - Selector checking

#pragma mark - Respoder rewrite

- (BOOL)respondsToSelector:(SEL)selector
{
    static BOOL useSelector;
    static dispatch_once_t predicate = 0;
    dispatch_once(&predicate, ^{
        useSelector = [[UIDevice currentDevice].systemVersion floatValue] < 8.0 ? YES : NO;
    });
    
    if (selector == @selector(tableView:heightForRowAtIndexPath:)) {
        return useSelector;
    }
    
    return [super respondsToSelector:selector];
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

@end
