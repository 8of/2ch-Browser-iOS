//
//  DVBAsyncBoardViewController.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 15/11/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBAsyncBoardViewController.h"
#import "DVBThread.h"
#import "DVBBoardModel.h"
#import "ThreadNode.h"
#import "DVBThreadViewController.h"

@interface DVBAsyncBoardViewController () <ASTableDataSource, ASTableDelegate>

@property (nonatomic, strong) ASTableNode *tableNode;
/// Board's shortcode.
@property (strong, nonatomic) NSString *boardCode;
/// MaxPage (i.e. page count) for specific board.
@property (assign, nonatomic) NSInteger pages;
@property (nonatomic, assign) NSInteger currentPage;
@property (atomic, assign) BOOL alreadyLoadingNextPage;
/// Array contains all threads' OP posts for one page.
@property (nonatomic, strong) NSMutableArray *threadsArray;
@property (nonatomic, strong) DVBBoardModel *boardModel;
/// Need property for know if we gonna create new thread or not.
@property (nonatomic, strong) NSString *createdThreadNum;

@end

@implementation DVBAsyncBoardViewController

- (instancetype)initBoardCode:(NSString *)boardCode pages:(NSInteger)pages
{
    _tableNode = [[ASTableNode alloc] initWithStyle:UITableViewStylePlain];
    
    self = [super initWithNode:_tableNode];
    
    if (self) {
        _boardCode = boardCode;
        _pages = pages;
        _tableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableNode.view.contentInset = UIEdgeInsetsMake(5, 0, 5, 0);
        _tableNode.delegate = self;
        _tableNode.dataSource = self;
        _tableNode.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
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
        // [self makeRefreshAvailable];
        [self reloadBoardPage];
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    // Because we need to turn off toolbar every time view appears, not only when it loads first time
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)reloadBoardPage
{
    // Prevent reloading while already loading board items
    if (_alreadyLoadingNextPage) {
        // [self.refreshControl endRefreshing];
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
         // [self.refreshControl endRefreshing];
         dispatch_async(dispatch_get_main_queue(), ^{
             [self.tableNode reloadData];
             self.alreadyLoadingNextPage = NO;
         });
     }];
}

#pragma mark - ASTableNode

- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBThread *thread = _boardModel.threadsArray[indexPath.row];
    return ^{
        return [[ThreadNode alloc] initWithThread:thread];
    };
}

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
    return _boardModel.threadsArray.count;
}

- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DVBThread *thread = _boardModel.threadsArray[indexPath.row];
    NSString *threadNum = thread.num;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:STORYBOARD_NAME_MAIN
                                                         bundle:nil];
    DVBThreadViewController *threadViewController = (DVBThreadViewController *)[storyboard instantiateViewControllerWithIdentifier:STORYBOARD_ID_THREAD_VIEW_CONTROLLER];
    threadViewController.boardCode = _boardCode;
    threadViewController.threadNum = threadNum;
    threadViewController.threadSubject = [DVBThread threadControllerTitleFromTitle:thread.subject andNum:thread.num andComment:thread.comment];
    [self.navigationController pushViewController:threadViewController animated:YES];
    [_tableNode deselectRowAtIndexPath:indexPath animated:YES];
}

@end
