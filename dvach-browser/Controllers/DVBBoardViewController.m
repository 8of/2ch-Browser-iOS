//
//  DVBBoardViewController.m
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBBoardModel.h"
#import "DVBThread.h"

#import "DVBBoardViewController.h"
#import "DVBThreadViewController.h"

#import "DVBThreadTableViewCell.h"

static NSInteger const DIFFERENCE_BEFORE_ENDLESS_FIRE = 200.0f;
static NSTimeInterval const MIN_TIME_INTERVAL_BEFORE_NEXT_THREAD_UPDATE = 3;

@interface DVBCommonTableViewController ()

- (void)showMessageAboutDataLoading;
- (void)showMessageAboutError;

@end

@interface DVBBoardViewController () <DVBCreatePostViewControllerDelegate>

@property (nonatomic, assign) NSInteger currentPage;
@property (atomic, assign) BOOL alreadyLoadingNextPage;
/// Array contains all threads' OP posts for one page.
@property (nonatomic, strong) NSMutableArray *threadsArray;
@property (nonatomic, strong) DVBBoardModel *boardModel;
/// Need property for know if we gonna create new thread or not.
@property (nonatomic, strong) NSString *createdThreadNum;

@property (nonatomic, assign) BOOL viewAlreadyAppeared;
@property (nonatomic, assign) BOOL alreadyDidTheSizeClassTrick;
@property (nonatomic, strong) NSDate *lastLoadDate;

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
    CGFloat cellHeight = PREVIEW_ROW_DEFAULT_HEIGHT + 1;
    if (IS_IPAD) {
        cellHeight = PREVIEW_ROW_DEFAULT_HEIGHT_IPAD + 1;
    }

    self.tableView.rowHeight = cellHeight;

    _viewAlreadyAppeared = NO;
    _alreadyDidTheSizeClassTrick = NO;
    _currentPage = 0;

    // set loading flag here because othervise
    // scrollViewDidScroll methods will start loading 'next' page (actually the same page) again
    _alreadyLoadingNextPage = NO;

    // If no pages setted (or pages is 0 - then set 10 pages).
    
    if (!_pages) {
        _pages = 10;
    }
    
    self.title = [NSString stringWithFormat:@"/%@/",_boardCode];
    _boardModel = [[DVBBoardModel alloc] initWithBoardCode:_boardCode
                                                andMaxPage:_pages];
    [self makeRefreshAvailable];
    _lastLoadDate = [NSDate dateWithTimeIntervalSince1970:0];
}

- (void)darkThemeHandler
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        self.tableView.backgroundColor = [UIColor blackColor];
    } else {
        self.tableView.backgroundColor = [UIColor whiteColor];
    }
}

/// First time loading thread list
- (void)loadNextBoardPage
{
    weakify(self);
    if (_pages > _currentPage)  {
        [_boardModel loadNextPageWithViewWidth:self.view.bounds.size.width
                                 andCompletion:^(NSArray *completionThreadsArray, NSError *error)
        {
            strongify(self);
            if (!self) { return; }
            NSInteger threadsCountWas = self.threadsArray.count ? self.threadsArray.count : 0;
            _threadsArray = [completionThreadsArray mutableCopy];
            NSInteger threadsCountNow = self.threadsArray.count ? self.threadsArray.count : 0;

            NSMutableArray *mutableIndexPathes = [@[] mutableCopy];

            for (NSInteger i = threadsCountWas; i < threadsCountNow; i++) {
                [mutableIndexPathes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
            if (self.threadsArray.count == 0) {
                [self showMessageAboutError];
                self.navigationItem.rightBarButtonItem.enabled = NO;
            } else {
                self.currentPage++;
                // Update only if we have something to show
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateTableSmoothlyForIndexPathes:mutableIndexPathes.copy];
                    self.alreadyLoadingNextPage = NO;
                    self.navigationItem.rightBarButtonItem.enabled = YES;
                    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
                    self.tableView.backgroundView = nil;
                    
                    if (!self.alreadyDidTheSizeClassTrick) {
                        self.alreadyDidTheSizeClassTrick = YES;
                        [self.tableView setNeedsLayout];
                        [self.tableView layoutIfNeeded];
                        [self.tableView reloadData];
                    }
                });
            }
            [self handleError:error];
        }];
    } else {
        _currentPage = 0;
        [self loadNextBoardPage];
    }
}

- (void)updateTableSmoothlyForIndexPathes:(NSArray *)indexPathes
{
    NSUInteger countOfSectionsbefore = self.tableView.numberOfSections;
    [self.tableView beginUpdates];

    // If this is the first insertions - insert section first
    if (!countOfSectionsbefore) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0]
                      withRowAnimation:UITableViewRowAnimationNone];
    }
    [self.tableView insertRowsAtIndexPaths:indexPathes
                          withRowAnimation:UITableViewRowAnimationBottom];
    [self.tableView endUpdates];
}

/// Allocating refresh controll - for fetching new updated result from server by pulling board table view down.
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
    } else {
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

    [(DVBThreadTableViewCell *)cell prepareCellWithComment:thread.comment
                                     andThumbnailUrlString:thread.thumbnail
                                             andPostsCount:thread.postsCount.stringValue
                                     andTimeSinceFirstPost:thread.timeSinceFirstPost];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBThreadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:THREAD_CELL_IDENTIFIER
                                                                   forIndexPath:indexPath];
    return cell;
}

- (void)reloadBoardPage
{
    // Prevent reloading while already loading board items
    if (_alreadyLoadingNextPage) {
        [self.refreshControl endRefreshing];
        return;
    }

    _alreadyLoadingNextPage = YES;
    weakify(self);
    [_boardModel reloadBoardWithViewWidth:self.view.bounds.size.width
                        andCompletion:^(NSArray *completionThreadsArray)
    {
        strongify(self);
        if (!self) { return; }
        self.currentPage = 0;
        self.threadsArray = [completionThreadsArray mutableCopy];
        [self.refreshControl endRefreshing];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            self.alreadyLoadingNextPage = NO;
        });
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:SEGUE_TO_THREAD]) {
        DVBThreadViewController *threadViewController = segue.destinationViewController;
        threadViewController.boardCode = _boardCode;
        
        if (_createdThreadNum) {
            // Set thread num the other way (not from threadObjects Array.
            threadViewController.threadNum = _createdThreadNum;

            // Set to nil in case we will dismiss this VC later and it'll try the same thead insted of opening the new one.
            _createdThreadNum = nil;
        } else {
            NSIndexPath *selectedCellPath = [self.tableView indexPathForSelectedRow];
            
            DVBThread *tempThreadObj;
            tempThreadObj = [_threadsArray objectAtIndex:selectedCellPath.row];
            
            NSString *threadNum = tempThreadObj.num;
            
            threadViewController.threadNum = threadNum;
            threadViewController.threadSubject = [DVBThread threadControllerTitleFromTitle:tempThreadObj.subject andNum:tempThreadObj.num andComment:tempThreadObj.comment];

        }
    } else if ([[segue identifier] isEqualToString:SEGUE_TO_NEW_THREAD_IPAD] || [[segue identifier] isEqualToString:SEGUE_TO_NEW_THREAD_IPHONE]) {
        
        DVBCreatePostViewController *createPostViewController = (DVBCreatePostViewController*) [[segue destinationViewController] topViewController];
        createPostViewController.createPostViewControllerDelegate = self;
        createPostViewController.threadNum = @"0";
        createPostViewController.boardCode = _boardCode;

        // Fix ugly white popover arrow on Popover Controller when dark theme enabled
        if ([[segue identifier] isEqualToString:SEGUE_TO_NEW_THREAD_IPAD] &&
            [[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME])
        {
            [segue destinationViewController].popoverPresentationController.backgroundColor = [UIColor blackColor];
        }
    }
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

    NSDate *now = [NSDate date];
    NSTimeInterval intervalSinceLastUpdate = [now timeIntervalSinceDate:_lastLoadDate];
    
    if ((offsetDifference < DIFFERENCE_BEFORE_ENDLESS_FIRE) &&
        !_alreadyLoadingNextPage &&
        (intervalSinceLastUpdate > MIN_TIME_INTERVAL_BEFORE_NEXT_THREAD_UPDATE))
    {
        _lastLoadDate = now;
        _alreadyLoadingNextPage = YES;
        [self loadNextBoardPage];
    }
}

#pragma mark - Orientation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.tableView reloadData];
}

#pragma mark - DVBDvachWebViewViewControllerProtocol

- (void)reloadAfterWebViewDismissing
{
    [self reloadBoardPage];
}

@end
