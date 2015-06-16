//
//  DVBThreadControllerTableViewManager.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 14/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBPost.h"
#import "DVBThreadControllerTableViewManager.h"

#import "DVBPostTableViewCell.h"

// Default row heights
static CGFloat const ROW_DEFAULT_HEIGHT = 64.0f;
static CGFloat const ROW_MEDIA_DEFAULT_HEIGHT = 74.0f;
static CGFloat const ROW_ACTIONS_DEFAULT_HEIGHT = 42.0f;
static CGFloat const ADDITIONAL_HEIGHT_FOR_POST_THUMB_ON_IPAD = 36.0f;
static CGFloat const ADDITIONAL_HEIGHT_FOR_MEDIA_ON_IPAD = 36.0f;

// Thumbnail width in post row
static CGFloat const THUMBNAIL_WIDTH = 64.f;
// Thumbnail contstraints for calculating layout dimentions
static CGFloat const HORISONTAL_CONSTRAINT = 10.0f; // we have 3 of them


@interface DVBThreadControllerTableViewManager ()

@property (nonatomic, strong) DVBThreadViewController *threadViewController;
@property (nonatomic, strong) DVBPostTableViewCell *prototypeCell;

@end

@implementation DVBThreadControllerTableViewManager

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Not enough info" reason:@"Use +[DVBThreadControllerTableViewManager initWithThreadViewController]" userInfo:nil];

    return nil;
}

- (instancetype)initWith:(DVBThreadViewController *)threadViewController
{
    self = [super init];

    if (self) {
        _threadViewController = threadViewController;

        // System do not spend resources on calculating row heights via heightForRowAtIndexPath.
        if (![self respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
            _threadViewController.tableView.estimatedRowHeight = ROW_DEFAULT_HEIGHT;
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                _threadViewController.tableView.estimatedRowHeight = ADDITIONAL_HEIGHT_FOR_POST_THUMB_ON_IPAD;
            }
        }
    }

    return self;
}

#pragma mark - Table view

// Separator insets to zero
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }

    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }

    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_postsArray.count > 0) {
        return _postsArray.count;
    }
    else {
        [_threadViewController showMessageAboutDataLoading];
    }

    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = (DVBPostTableViewCell *) [tableView dequeueReusableCellWithIdentifier:POST_CELL_IDENTIFIER
                                                                                     forIndexPath:indexPath];
    [self configureCell:cell
      forRowAtIndexPath:indexPath];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBPost *post = _postsArray[indexPath.section];

    // Additional calculations for title
    UIFont *fontFromSettings = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_LITTLE_BODY_FONT]) {
        fontFromSettings = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    }
    CGSize size = [post.num sizeWithAttributes:@{NSFontAttributeName:fontFromSettings}];
    CGFloat titleHeight = size.height + HORISONTAL_CONSTRAINT * 2;

    // Additional calculations for 4-in-line-media
    CGFloat additionalHeightForMedia = 0;
    if ([post.thumbPathesArray count] > 1) { // If post have more than one thumbnail and this is first row
        additionalHeightForMedia = ROW_MEDIA_DEFAULT_HEIGHT;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            additionalHeightForMedia = additionalHeightForMedia + ADDITIONAL_HEIGHT_FOR_MEDIA_ON_IPAD;
        }
    }

    // Helper method to get the text at a given cell.
    NSAttributedString *text = [self getTextAtIndex:indexPath];

    // Getting the width/height needed by the dynamic text view.
    CGSize viewSize = _threadViewController.tableView.bounds.size;
    NSInteger viewWidth = viewSize.width;

    // Set default difference (if we hve image in the cell).
    CGFloat widthDifferenceBecauseOfImageAndConstraints = HORISONTAL_CONSTRAINT * 2;

    // If not - then set the difference just to two constraints.
    if ([post.thumbPathesArray count] == 1) {
        widthDifferenceBecauseOfImageAndConstraints = widthDifferenceBecauseOfImageAndConstraints + THUMBNAIL_WIDTH + HORISONTAL_CONSTRAINT;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            widthDifferenceBecauseOfImageAndConstraints = widthDifferenceBecauseOfImageAndConstraints + ADDITIONAL_HEIGHT_FOR_POST_THUMB_ON_IPAD;
        }
    }

    // Decrease window width value by taking off elements and contraints values
    CGFloat textViewWidth = viewWidth - widthDifferenceBecauseOfImageAndConstraints;

    // Return the size of the current row.
    CGFloat heightToReturn = [self heightForText:text
                               constrainedToSize:CGSizeMake(textViewWidth, CGFLOAT_MAX)];

    CGFloat additionalHeightForActionButtons = ROW_ACTIONS_DEFAULT_HEIGHT; // Row actions include button height and also 2 x 10px constraints height

    CGFloat heightForReturnWithCorrectionAndCeilf = ceilf(heightToReturn + additionalHeightForMedia + titleHeight + additionalHeightForActionButtons);

    heightForReturnWithCorrectionAndCeilf = heightForReturnWithCorrectionAndCeilf + 1;

    CGFloat minimumTextRowHeightToCompareTo = titleHeight + additionalHeightForMedia + additionalHeightForActionButtons + ROW_DEFAULT_HEIGHT + 1;

    // Check if we have 2-4 images on top and no comment text at all - we need to delete one extra horisontal constraint
    BOOL isPostHasCommentText = ![post.comment isEqualToAttributedString:[[NSAttributedString alloc] initWithString:@""]];
    if (!isPostHasCommentText && ([post.thumbPathesArray count] > 1)) {
        heightForReturnWithCorrectionAndCeilf = heightForReturnWithCorrectionAndCeilf - HORISONTAL_CONSTRAINT * 2; // still not sure why we need x2 here
        minimumTextRowHeightToCompareTo = minimumTextRowHeightToCompareTo - HORISONTAL_CONSTRAINT * 2; // still not sure why we need x2 here
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        minimumTextRowHeightToCompareTo = minimumTextRowHeightToCompareTo + ADDITIONAL_HEIGHT_FOR_POST_THUMB_ON_IPAD;
    }

    // Check if comment is too short compare to thumbnail on the left
    if (heightForReturnWithCorrectionAndCeilf < minimumTextRowHeightToCompareTo) {
        if (([post.thumbPathesArray count] == 0) || ([post.thumbPathesArray count] > 1)) {
            return heightForReturnWithCorrectionAndCeilf;
        }

        return (minimumTextRowHeightToCompareTo);
    }

    return heightForReturnWithCorrectionAndCeilf;

    
    return 0;
}

#pragma mark - Cell configuration and calculation

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[DVBPostTableViewCell class]]) {
        DVBPostTableViewCell *confCell = (DVBPostTableViewCell *)cell;
        DVBPost *post = _postsArray[indexPath.section];

        // Configure title
        NSString *dateAgo = post.dateAgo;
        NSString *num = post.num;
        // Need to increase number by one because sections start count from 0 and post counts on 2ch commonly start with 1
        NSInteger postNumToShow = indexPath.section + 1;
        NSString *title = [[NSString alloc] initWithFormat:@"#%ld • %@ • %@", (long)postNumToShow, num, dateAgo];

        // Configure post itself
        confCell.threadViewController = _threadViewController;

        // Configure action buttons
        NSUInteger indexForButton = indexPath.section;
        BOOL shouldDisableActionButton = NO;
        if (_answersToPost) {
            shouldDisableActionButton = YES;
        }

        [confCell prepareCellWithTitle:title
                        andCommentText:post.comment
               andWithPostRepliesCount:[post.replies count]
                              andIndex:indexForButton
                andDisableActionButton:shouldDisableActionButton
                   andThumbPathesArray:post.thumbPathesArray
                        andPathesArray:post.pathesArray];
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
 *  Source for the text to be rendered in the text view.
 *  I used a dictionary to map indexPath to some dynamically fetched text.
 */
- (NSAttributedString *)getTextAtIndex:(NSIndexPath *)indexPath
{

    NSUInteger tmpIndex = indexPath.section;
    DVBPost *tmpObj =  _postsArray[tmpIndex];
    NSAttributedString *tmpComment = tmpObj.comment;

    return tmpComment;
}

#pragma mark - Scroll Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Trying to figure out scroll position to store it for restoring later
    if (scrollView.contentOffset.y > 100) {
        // When we go back - table jumps in this values - so the correction is needed here
        CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;

        CGFloat topBarDifference = MIN(statusBarSize.width, statusBarSize.height) + _threadViewController.navigationController.navigationBar.frame.size.height;

        if (topBarDifference >= _threadViewController.topBarDifference) {
            _threadViewController.topBarDifference = topBarDifference;
        }

        CGFloat scrollPositionToStore = scrollView.contentOffset.y - _threadViewController.topBarDifference;

        NSNumber *scrollPosition = [NSNumber numberWithFloat:scrollPositionToStore];

        [_threadViewController.threadsScrollPositionManager.threads setValue:scrollPosition
                                                 forKey:_threadViewController.threadNum];
        
        _threadViewController.autoScrollTo = [_threadViewController.threadsScrollPositionManager.threads
                         objectForKey:_threadViewController.threadNum];
    }
}


@end
