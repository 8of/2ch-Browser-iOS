//
//  DVBThreadViewController.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 11/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <UINavigationItem+Loading.h>

#import "DVBConstants.h"
#import "Reachlibility.h"
#import "DVBThreadModel.h"
#import "DVBNetworking.h"
#import "DVBPost.h"
#import "DVBBadPost.h"
#import "DVBComment.h"

#import "DVBThreadViewController.h"
#import "DVBCreatePostViewController.h"
#import "DVBBrowserViewControllerBuilder.h"

#import "DVBPostTableViewCell.h"
#import "DVBMediaForPostTableViewCell.h"

// default row height
static CGFloat const ROW_DEFAULT_HEIGHT = 130.0f;
static CGFloat const ROW_MEDIA_DEFAULT_HEIGHT = 73.0f;

// thumbnail width in post row
static CGFloat const THUMBNAIL_WIDTH = 65.f;
// thumbnail contstraints for calculating layout dimentions
static CGFloat const HORISONTAL_CONSTRAINT = 8.0f; // we have 3 of them

/**
 *  Correction height because of:
 *  action-answer buttons - 30
 *  constraint from text to top - 8
 *  border - 1 more
 *  just in case I added one more :)
 */
static CGFloat const CORRECTION_HEIGHT_FOR_TEXT_VIEW_CALC = 40.0f;

@protocol sendDataProtocol <NSObject>

- (void)sendDataToBoard:(NSUInteger)deletedObjectIndex;

@end

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

@end

@implementation DVBThreadViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self toolbarHandler];
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
        [self.navigationController setToolbarHidden:NO animated:NO];
        [self.navigationItem startAnimatingAt:ANNavBarLoaderPositionRight];
        // Set view controller title depending on...
        self.title = [self getSubjectOrNumWithSubject:_threadSubject
                                         andThreadNum:_threadNum];
        _threadModel = [[DVBThreadModel alloc] initWithBoardCode:_boardCode
                                                    andThreadNum:_threadNum];
    }
    
    // System do not spend resurces on calculating row heights via heightForRowAtIndexPath.
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

/// Set every section title depending on post SUBJECT or NUMBER
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    DVBPost *postTmpObj = _postsArray[section];
    NSString *subject = postTmpObj.subject;
    NSString *date = postTmpObj.date;
    
    subject = [self getSubjectOrNumWithSubject:subject
                                  andThreadNum:postTmpObj.num];
    
    // we increase number by one because sections start count from 0 and post counts on 2ch commonly start with 1
    NSInteger postNumToShow = section + 1;
    
    NSString *sectionTitle = [[NSString alloc] initWithFormat:@"#%ld %@ - %@", (long)postNumToShow, subject, date];
    
    return sectionTitle;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    DVBPost *post = _postsArray[section];

    // If post have more than one thumbnail...
    if ([post.thumbPathesArray count] > 1) {
        return 2;
    }

    return 1;
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

    // If post have more than one thumbnail...
    if (([post.thumbPathesArray count] > 1)&&(row == 0)) {
        return ROW_MEDIA_DEFAULT_HEIGHT;
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
        
        UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        
        CGSize size = [self frameForText:text
                            sizeWithFont:font
                       constrainedToSize:CGSizeMake(textViewWidth, CGFLOAT_MAX)];
        
        // Return the size of the current row.
        // 81 is the minimum height! Update accordingly
        CGFloat heightToReturn = size.height;
        
        CGFloat heightForReturnWithCorrectionAndCeilf = ceilf(heightToReturn + CORRECTION_HEIGHT_FOR_TEXT_VIEW_CALC);
        
        if (heightToReturn < ROW_DEFAULT_HEIGHT) {

            if ([thumbPath isEqualToString:@""]) {
                return heightForReturnWithCorrectionAndCeilf;
            }
            
            return ROW_DEFAULT_HEIGHT;
        }

        // We should not return values greater than 2009
        if (heightForReturnWithCorrectionAndCeilf > 2008) {
            return 2008;
        }
        
        return heightForReturnWithCorrectionAndCeilf;
    }

    return 0;
}

// We do not need this because we set it in another place.
/*
- (CGFloat)tableView:(UITableView *)tableView
estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBPost *selectedPost = _postsArray[indexPath.section];
    
    NSString *fullUrlString = selectedPost.path;
    
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
                NSLog(@"Need VLC to open this");
                NSString *installVLCPrompt = NSLocalizedString(@"Для просмотра установите VLC", @"Prompt in navigation bar of a thread View Controller - shows after user tap on the video and if user do not have VLC on the device");
                self.navigationItem.prompt = installVLCPrompt;
                [self performSelector:@selector(clearPrompt)
                           withObject:nil
                           afterDelay:2.0];
            }
        }
        // if not
        else {
            [self handleTapOnImageViewWithIndexPath:indexPath];
        }
    }
}

- (BOOL)isLinkInternalWithLink:(UrlNinja *)url
{
    switch (url.type) {
        case boardLink: {
            //открыть борду
            /*
            BoardViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BoardTag"];
            controller.boardId = urlNinja.boardId;
            [self.navigationController pushViewController:controller animated:YES];
            */
            
            return NO;
            
            break;
        }
        case boardThreadLink: {
            // [self openThreadWithUrlNinja:urlNinja];

            return NO;
            
            break;
        }
        case boardThreadPostLink: {

            // if we do not have boardId of threadNum assidned - we take them from passed url
            if (!_threadNum) {
                _threadNum = url.threadId;
            }
            if (!_boardCode) {
                _boardCode = url.boardId;
            }

            //если это этот же тред, то он открывается локально, иначе открывается весь тред со скроллом
            if ([_threadNum isEqualToString:url.threadId] && [_boardCode isEqualToString:url.boardId]) {
                [self openPostWithUrlNinja:url];

                return YES;
                /*
                if ([self.thread.linksReference containsObject:urlNinja.postId]) {
                    [self openPostWithUrlNinja:urlNinja];
                    return NO;
                }
                 */
            }
            // [self openThreadWithUrlNinja:urlNinja];
        }
            break;
        default: {
            // [self makeExternalLinkActionSheetWithUrl:URL];

            return NO;
            
            break;
        }
    }
    NSLog(@"url type: %lu", (unsigned long)url.type);

    return YES;
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

/// Clear prompt of any status / error messages.
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
        NSUInteger indexForButton = indexPath.section;

        BOOL showVideoIcon = (post.mediaType == webm);
        
        [confCell prepareCellWithCommentText:post.comment
                       andPostThumbUrlString:thumbUrlString
                         andPostRepliesCount:[post.replies count]
                                    andIndex:indexForButton
                            andShowVideoIcon:showVideoIcon];
        
        confCell.threadViewController = self;

        if (_answersToPost) {
            confCell.disableActionButton = YES;
        }
    }
}

- (void)configureMediaCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[DVBMediaForPostTableViewCell class]]) {
        DVBPost *post = _postsArray[indexPath.section];

        DVBMediaForPostTableViewCell *confCell = (DVBMediaForPostTableViewCell *)cell;
        confCell.threadViewController = self;
        [confCell prepareCellWithThumbPathesArray:post.thumbPathesArray andPathesArray:post.pathesArray];
    }
}

/// Utility function that given text, calculates how much space we need to fit that text. Calculation for texView height.
-(CGSize)frameForText:(NSAttributedString *)text sizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size
{
    CGRect frame = [text boundingRectWithSize:size
                                      options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                      context:nil];
    
    /**
     *  This contains both height and width, but we really care only about height.
     */
    return frame.size;
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
            });
            [self.navigationItem stopAnimating];
        }];
    }
}

- (void)reloadThreadFromOutside
{
    [self reloadThread];
}

#pragma mark - Actions from Storyboard

- (IBAction)reloadThreadAction:(id)sender
{
    [self reloadThread];
}

- (IBAction)scrollToBottom:(id)sender
{
    CGPoint pointToScrollTo = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height);
    [self.tableView setContentOffset:pointToScrollTo animated:YES];
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

    [self.navigationController pushViewController:threadViewController animated:YES];
}

- (IBAction)showPostActions:(id)sender
{
    UIButton *answerButton = sender;
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
                           @"Открыть в браузере",
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

            case 2: // share
            {
                NSString *urlToShare = [[NSString alloc] initWithFormat:@"%@%@/res/%@.html", DVACH_BASE_URL, _boardCode, _threadNum];
                [self callShareControllerWithUrlString:urlToShare];
                break;
            }
                
            case 3: // open in browser button
            {
                NSString *urlToOpen = [[NSString alloc] initWithFormat:@"%@%@/res/%@.html", DVACH_BASE_URL, _boardCode, _threadNum];
                NSLog(@"URL: %@", urlToOpen);
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlToOpen]];
                break;
            }
                
            case 4:
            {
                // Flag button
                [self sendPost:_flaggedPostNum andBoard:_boardCode andCompletion:^(BOOL done) {
                    NSLog(@"Post complaint sent.");
                    if (done) {
                        [self deletePostWithIndex:_selectedWithLongPressSection andFlaggedPostNum:_flaggedPostNum];
                    }
                }];
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

    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];

    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Bad posts reporting

/// Function for flag inappropriate content and send it to moderators DB
- (void) sendPost:(NSString *)postNum andBoard:(NSString *)board andCompletion:(void (^)(BOOL ))completion
{
    NSString *currentPostNum = postNum;
    NSString *currentBoard = board;
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        NSLog(@"Cannot find internet.");
        BOOL result = NO;
        return completion(result);
    }
    else {
        
        // building URL for sendin JSON to my server (for tickets)
        // there is better one-line solution for this - need to use stringWithFormat
        // rewrite in future!
        
        NSMutableString *requestAddress = [[NSMutableString alloc] initWithString:COMPLAINT_URL];
        [requestAddress appendString:@"?postnum="];
        [requestAddress appendString:currentPostNum];
        [requestAddress appendString:@"&board="];
        [requestAddress appendString:currentBoard];
        
        NSURLRequest *activeRequest = [NSURLRequest requestWithURL:
                                       [NSURL URLWithString:requestAddress]];
        
        [NSURLConnection sendAsynchronousRequest:activeRequest
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response,
                                                   NSData *data,
                                                   NSError *connectionError)
         {
             NSError *jsonError;
             
             NSMutableDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:data
                                                                               options:NSJSONReadingAllowFragments
                                                                                 error:&jsonError];
             
             NSString *status = resultDict[@"status"];
             
             BOOL ok = YES;
             
             if (![status isEqualToString:@"1"])
             {
                 completion(NO);
             }
             
             completion(ok);
         }];
    }
}

- (void)deletePostWithIndex:(NSUInteger)index andFlaggedPostNum:(NSString *)flaggedPostNum
{
    [_threadModel flagPostWithIndex:index andFlaggedPostNum:flaggedPostNum andOpAlreadyDeleted:_opAlreadyDeleted];
    
    if (index == 0) {
        [self.delegate sendDataToBoard:_threadIndex];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [self.tableView reloadData];
        [self showAlertAboutReportedPost];
    }
}

- (void)showAlertAboutReportedPost
{
    NSString *complaintSentAlertTitle = NSLocalizedString(@"Жалоба отправлена", @"Заголовок alert'a сообщает о том, что жалоба отправлена.");
    NSString *complaintSentAlertMessage = NSLocalizedString(@"Ваша жалоба посталена в очередь на проверку модератором. Пост был скрыт.", @"Текст alert'a сообщает о том, что жалоба отправлена.");
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:complaintSentAlertTitle
                                                        message:complaintSentAlertMessage
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
    [alertView setTag:1];
    [alertView show];
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
                NSLog(@"Need VLC to open this");
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

// Tap on image method
- (void)handleTapOnImageViewWithIndexPath:(NSIndexPath *)indexPath
{
    [self createAndPushGalleryWithIndexPath:indexPath];
}

// New approach
- (void)createAndPushGalleryWithUrlString:(NSString *)urlString
{
    DVBBrowserViewControllerBuilder *galleryBrowser = [[DVBBrowserViewControllerBuilder alloc] initWithDelegate:nil];

    NSUInteger indexForImageShowing = [_fullImagesArray indexOfObject:urlString];

    if (indexForImageShowing < [_fullImagesArray count]) {

        [galleryBrowser prepareWithIndex:indexForImageShowing
                     andThumbImagesArray:_thumbImagesArray
                      andFullImagesArray:_fullImagesArray];

        // Present
        [self.navigationController pushViewController:galleryBrowser animated:YES];
    }
}

// old approach
- (void)createAndPushGalleryWithIndexPath:(NSIndexPath *)indexPath
{
    DVBBrowserViewControllerBuilder *galleryBrowser = [[DVBBrowserViewControllerBuilder alloc] initWithDelegate:nil];

    NSUInteger indexForImageShowing = indexPath.section;
    DVBPost *postObj = _postsArray[indexForImageShowing];
    NSString *path = postObj.path;
    NSUInteger index = [_fullImagesArray indexOfObject:path];
    
    [galleryBrowser prepareWithIndex:index
          andThumbImagesArray:_thumbImagesArray
           andFullImagesArray:_fullImagesArray];

    // Present
    [self.navigationController pushViewController:galleryBrowser animated:YES];
}

#pragma mark - DVBCreatePostViewControllerDelegate

-(void)updateThreadAfterPosting
{
    // Update Thread from network.
    [self reloadThread];
    
    // Scroll thread to bottom. Not working as it should for now.
    CGPoint pointToScrollTo = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height);
    [self.tableView setContentOffset:pointToScrollTo animated:YES];
    
    NSLog(@"Table updated after posting.");
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

@end
