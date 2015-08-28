//
//  DVBBoardViewController.m
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBBoardModel.h"

#import "DVBBoardViewController.h"
#import "DVBThreadViewController.h"

#import "DVBThreadTableViewCell.h"

static CGFloat const ROW_DEFAULT_HEIGHT = 86.0f;
static CGFloat const ROW_DEFAULT_HEIGHT_IPAD = 120.0f;
static NSInteger const DIFFERENCE_BEFORE_ENDLESS_FIRE = 50.0f;

@interface DVBCommonTableViewController ()

- (void)showMessageAboutDataLoading;
- (void)showMessageAboutError;

@end

@interface DVBBoardViewController () <DVBCreatePostViewControllerDelegate>

@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL alreadyLoadingNextPage;
/// Array contains all threads' OP posts for one page.
@property (nonatomic, strong) NSMutableArray *threadsArray;
@property (nonatomic, strong) DVBBoardModel *boardModel;
/// Need property for know if we gonna create new thread or not.
@property (nonatomic, strong) NSString *createdThreadNum;

@property (nonatomic, assign) BOOL viewAlreadyAppeared;
@property (nonatomic, assign) BOOL alreadyDidTheSizeClassTrick;

@end

@implementation DVBBoardViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];

    // Because we need to turn off toolbar every time view appears, not only when it loads first time
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];
    _viewAlreadyAppeared = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self darkThemeHandler];

    _viewAlreadyAppeared = NO;
    _alreadyDidTheSizeClassTrick = NO;
    
    _currentPage = 0;

    // set loading flag here because othervise
    // scrollViewDidScroll methods will start loading 'next' page (actually the same page) again
    _alreadyLoadingNextPage = YES;

    // If no pages setted (or pages is 0 - then set 10 pages).
    if (!_pages) {
        _pages = 10;
    }
    
    self.title = [NSString stringWithFormat:@"/%@/",_boardCode];
    
    _boardModel = [[DVBBoardModel alloc] initWithBoardCode:_boardCode
                                                andMaxPage:_pages];
    [self loadNextBoardPage];
    [self makeRefreshAvailable];

    // System do not spend resources on calculating row heights via heightForRowAtIndexPath.
    if (![self respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            self.tableView.estimatedRowHeight = ROW_DEFAULT_HEIGHT_IPAD + 1;
            self.tableView.rowHeight = ROW_DEFAULT_HEIGHT_IPAD + 1;
        }
        else {
            self.tableView.estimatedRowHeight = ROW_DEFAULT_HEIGHT + 1;
        }

        self.tableView.rowHeight = UITableViewAutomaticDimension;
    }
}

- (void)darkThemeHandler
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        self.tableView.backgroundColor = [UIColor blackColor];
    }
}

/// First time loading thread list
- (void)loadNextBoardPage
{
    if (_pages > _currentPage)  {
        [_boardModel loadNextPageWithCompletion:^(NSArray *completionThreadsArray)
        {
            _threadsArray = [completionThreadsArray mutableCopy];
            _currentPage++;
            _alreadyLoadingNextPage = NO;

            if (_threadsArray.count == 0) {
                [self showMessageAboutError];
                self.navigationItem.rightBarButtonItem.enabled = NO;
            } else {
                // Update only if we have something to show
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    self.navigationItem.rightBarButtonItem.enabled = YES;
                    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
                    self.tableView.backgroundView = nil;
                    if (!_alreadyDidTheSizeClassTrick) {
                        [self.tableView setNeedsLayout];
                        [self.tableView layoutIfNeeded];
                        [self.tableView reloadData];
                    }
                });
            }
        }];
    } else {
        _currentPage = 0;
        [self loadNextBoardPage];
    }
}

/**
 Allocating refresh controll - for fetching new updated result from server by pulling board table view down.
 */
- (void)makeRefreshAvailable
{
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(reloadBoardPage)
                  forControlEvents:UIControlEventValueChanged];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_threadsArray.count > 0) {
        return 1;
    }
    else {
        [self showMessageAboutDataLoading];
    }

    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _threadsArray.count;
}

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

    DVBThread *thread = [_threadsArray objectAtIndex:indexPath.row];
    NSString *title = thread.subject;
    if ([title isEqualToString:@""]) {
        title = thread.num;
    }

    [(DVBThreadTableViewCell *)cell prepareCellWithTitle:title
                    andComment:thread.comment
         andThumbnailUrlString:thread.thumbnail
                 andPostsCount:[thread.postsCount stringValue]
         andTimeSinceFirstPost:thread.timeSinceFirstPost];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBThreadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:THREAD_CELL_IDENTIFIER
                                                                   forIndexPath:indexPath];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat heightToReturn = ROW_DEFAULT_HEIGHT + 1;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        heightToReturn = ROW_DEFAULT_HEIGHT_IPAD + 1;
    }

    return heightToReturn;
}

- (void)reloadBoardPage
{
    _alreadyLoadingNextPage = YES;
    [_boardModel reloadBoardWithCompletion:^(NSArray *completionThreadsArray)
    {
        _currentPage = 0;
        _alreadyLoadingNextPage = NO;
        _threadsArray = [completionThreadsArray mutableCopy];
        [self.refreshControl endRefreshing];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:SEGUE_TO_THREAD]) {
        DVBThreadViewController *threadViewController = segue.destinationViewController;
        threadViewController.boardCode = _boardCode;
        
        if (_createdThreadNum) {
            // Set thread num the other way (not from threadObjects Array.
            threadViewController.threadNum = _createdThreadNum;

            // Set to nil in case we will dismiss this VC later and it'll try the same thead insted of opening the new one.
            _createdThreadNum = nil;
        }
        else {
            NSIndexPath *selectedCellPath = [self.tableView indexPathForSelectedRow];
            
            DVBThread *tempThreadObj;
            tempThreadObj = [_threadsArray objectAtIndex:selectedCellPath.row];
            
            NSString *threadNum = tempThreadObj.num;
            NSString *threadSubject = tempThreadObj.subject;
            
            threadViewController.threadNum = threadNum;
            threadViewController.threadSubject = threadSubject;
        }
    }
    else if ([[segue identifier] isEqualToString:SEGUE_TO_NEW_THREAD] || [[segue identifier] isEqualToString:SEGUE_TO_NEW_THREAD_IOS_7]) {
        
        DVBCreatePostViewController *createPostViewController = (DVBCreatePostViewController*) [[segue destinationViewController] topViewController];
        createPostViewController.createPostViewControllerDelegate = self;
        createPostViewController.threadNum = @"0";
        createPostViewController.boardCode = _boardCode;
    }
}

// We need to twick our segues a little because of difference between iOS 7 and iOS 8 in segue types
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // if we have Device with version under 8.0
    if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {

        // and we have fancy popover 8.0 segue
        if ([identifier isEqualToString:SEGUE_TO_NEW_THREAD]) {

            // Execute iOS 7 segue
            [self performSegueWithIdentifier:SEGUE_TO_NEW_THREAD_IOS_7 sender:self];

            // drop iOS 8 segue
            return NO;
        }

        return YES;
    }

    return YES;
}

- (void)openThredWithCreatedThread:(NSString *)threadNum
{
    _createdThreadNum = threadNum;
    [self performSegueWithIdentifier:SEGUE_TO_THREAD
                              sender:self];
}

#pragma mark - Scroll Delegate

// Check scroll position - we need it to load additional pages
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offsetDifference = self.tableView.contentSize.height - self.tableView.contentOffset.y - self.tableView.bounds.size.height;
    
    if ((offsetDifference < DIFFERENCE_BEFORE_ENDLESS_FIRE) && (!_alreadyLoadingNextPage)) {
        _alreadyLoadingNextPage = YES;
        [self loadNextBoardPage];
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

#pragma mark - Orientation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.tableView reloadData];
}

@end
