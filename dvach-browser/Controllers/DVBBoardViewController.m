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

static NSInteger const DIFFERENCE_BEFORE_ENDLESS_FIRE = 1000.0f;

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

@end

@implementation DVBBoardViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];

    // Because we need to turn off toolbar every time view appears, not only when it loads first time
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
            else if (!_wrongBoardAlertAlreadyPresentedOnce) {

                // Update only if we have something to show

                [self.navigationItem stopAnimating];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
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

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBThreadTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:THREAD_CELL_IDENTIFIER
                                                                   forIndexPath:indexPath];
    DVBThread *threadTmpObj = [_threadsArray objectAtIndex:indexPath.section];
    
    [cell prepareCellWithThreadObject:threadTmpObj];
    
    return cell;
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
        [self.navigationItem stopAnimating];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:SEGUE_TO_THREAD])
    {
        DVBThreadViewController *threadViewController = segue.destinationViewController;
        threadViewController.delegate = self;
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
    else if ([[segue identifier] isEqualToString:SEGUE_TO_NEW_THREAD]) {
        
        DVBCreatePostViewController *createPostViewController = (DVBCreatePostViewController*) [[segue destinationViewController] topViewController];
        createPostViewController.createPostViewControllerDelegate = self;
        createPostViewController.threadNum = @"0";
        createPostViewController.boardCode = _boardCode;
    }
}

- (void)sendDataToBoard:(NSUInteger)deletedObjectIndex
{
    [_threadsArray removeObjectAtIndex:deletedObjectIndex];
    [self.tableView reloadData];
    
    NSString *complaintSentAlertTitle = NSLocalizedString(@"Жалоба отправлена", @"Заголовок alert'a сообщает о том, что жалоба отправлена.");
    NSString *complaintSentAlertMessage = NSLocalizedString(@"Ваша жалоба поставлена в очередь на проверку. Тред был скрыт.", @"Текст alert'a сообщает о том, что жалоба отправлена.");
    UIAlertView *alertView = [_alertViewGenerator alertViewWithTitle:complaintSentAlertTitle
                                                         description:complaintSentAlertMessage
                                                             buttons:nil];
    [alertView show];
    
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

@end
