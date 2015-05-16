//
//  DVBBoardViewController.m
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <UINavigationItem+Loading.h>

#import "DVBConstants.h"
#import "DVBBoardModel.h"
#import "DVBAlertViewGenerator.h"

#import "DVBBoardViewController.h"
#import "DVBThreadViewController.h"

#import "DVBThreadTableViewCell.h"

static CGFloat const ROW_DEFAULT_HEIGHT = 85.0f;
static CGFloat const ROW_DEFAULT_HEIGHT_IPAD = 120.0f;
static NSInteger const DIFFERENCE_BEFORE_ENDLESS_FIRE = 200.0f;

@interface DVBBoardViewController () <DVBCreatePostViewControllerDelegate>

@property (nonatomic, strong) DVBAlertViewGenerator *alertViewGenerator;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) BOOL alreadyLoadingNextPage;
/**
 *  Array contains all threads' OP posts for one page.
 */
@property (nonatomic, strong) NSMutableArray *threadsArray;
@property (nonatomic, strong) DVBBoardModel *boardModel;
/**
 *  We need property for know if we gonna create new thread or not.
 */
@property (strong, nonatomic) NSString *createdThreadNum;

// Yes if we already know that board code was wrong and already presented user alert with this info
@property (nonatomic, assign) BOOL wrongBoardAlertAlreadyPresentedOnce;
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
    if (_wrongBoardAlertAlreadyPresentedOnce) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    if (!_wrongBoardAlertAlreadyPresentedOnce) {
        // Present loading indicator on the right.
        [self.navigationItem startAnimatingAt:ANNavBarLoaderPositionRight];

        [self loadNextBoardPage];
        [self makeRefreshAvailable];
    }

    if (!_alertViewGenerator) {
        _alertViewGenerator = [[DVBAlertViewGenerator alloc] init];
        _alertViewGenerator.alertViewGeneratorDelegate = nil;
    }

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

/**
 *  First time loading thread list
 */
- (void)loadNextBoardPage
{
    if (_pages > _currentPage)  {
        [_boardModel loadNextPageWithCompletion:^(NSArray *completionThreadsArray)
        {
            _threadsArray = [completionThreadsArray mutableCopy];
            _currentPage++;
            _alreadyLoadingNextPage = NO;
            
            // Show alert if board is not exist and we do not already show user alert
            if (([_threadsArray count] == 0) && (!_wrongBoardAlertAlreadyPresentedOnce)) {
                NSString *nonExistingBoardAlertHeader = NSLocalizedString(@"Доска не существует", @"Заголовок alert'a сообщает о том, что доска с таким кодом не существует.");
                
                UIAlertView *alertView =  [_alertViewGenerator
                                           alertViewWithTitle:nonExistingBoardAlertHeader
                                           description:nil
                                           buttons:nil];
                [alertView show];

                _wrongBoardAlertAlreadyPresentedOnce = YES;
                
                // Go back if board isn't there
                if (_viewAlreadyAppeared) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            }
            else if (!_wrongBoardAlertAlreadyPresentedOnce) {
                // Update only if we have something to show
                [self.navigationItem stopAnimating];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];

                    if (!_alreadyDidTheSizeClassTrick) {
                        [self.tableView setNeedsLayout];
                        [self.tableView layoutIfNeeded];
                        [self.tableView reloadData];
                    }
                });
            }
        }];
    }
    else
    {
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
    return [_threadsArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    DVBThread *threadTmpObj = [_threadsArray objectAtIndex:section];
    
    /**
     *  Get subject from OP post subject variable or set subject to number post.
     */
    NSString *subject = threadTmpObj.subject;
    if ([subject isEqualToString:@""])
    {
        subject = threadTmpObj.num;
    }

    return subject;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBThreadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:THREAD_CELL_IDENTIFIER
                                                                   forIndexPath:indexPath];
    DVBThread *threadTmpObj = [_threadsArray objectAtIndex:indexPath.section];

    [cell prepareCellWithThreadObject:threadTmpObj];
    
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
            [self.navigationItem stopAnimating];
        });
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:SEGUE_TO_THREAD])
    {
        DVBThreadViewController *threadViewController = segue.destinationViewController;
        threadViewController.boardCode = _boardCode;
        
        if (_createdThreadNum) {
            /**
             *  Set thread num the other way (not from threadObjects Array.
             */
            threadViewController.threadNum = _createdThreadNum;
            
            /**
             *  Set to nil in case we will dismiss this VC later and it'll try the same thead insted of opening the new one.
             */
            _createdThreadNum = nil;
        }
        else {
            NSIndexPath *selectedCellPath = [self.tableView indexPathForSelectedRow];
            
            DVBThread *tempThreadObj;
            tempThreadObj = [_threadsArray objectAtIndex:selectedCellPath.section];
            
            NSString *threadNum = tempThreadObj.num;
            NSString *threadSubject = tempThreadObj.subject;

            threadViewController.threadIndex = selectedCellPath.section;
            
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
    CGFloat actualPosition = self.tableView.contentOffset.y;
    CGFloat contentHeight = self.tableView.contentSize.height - DIFFERENCE_BEFORE_ENDLESS_FIRE;
    
    if ((actualPosition >= contentHeight) && (!_alreadyLoadingNextPage)) {
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

@end
