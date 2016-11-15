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

@property (nonatomic, assign) BOOL viewAlreadyAppeared;
@property (nonatomic, assign) BOOL alreadyDidTheSizeClassTrick;
@property (nonatomic, strong) NSDate *lastLoadDate;

@end

@implementation DVBAsyncBoardViewController

- (instancetype)initBoardCode:(NSString *)boardCode pages:(NSInteger)pages
{
    _tableNode = [[ASTableNode alloc] initWithStyle:UITableViewStylePlain];
    
    self = [super initWithNode:_tableNode];
    
    if (self) {
        _boardCode = boardCode;
        _pages = pages;

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
        _lastLoadDate = [NSDate dateWithTimeIntervalSince1970:0];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // SocialAppNode has its own separator
    self.tableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    // Because we need to turn off toolbar every time view appears, not only when it loads first time
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self reloadBoardPage];
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
//    PostNode *postNode = (PostNode *)[_tableNode nodeForRowAtIndexPath:indexPath];
//    Post *post = self.socialAppDataSource[indexPath.row];
//    
//    BOOL shouldRasterize = postNode.shouldRasterizeDescendants;
//    shouldRasterize = !shouldRasterize;
//    postNode.shouldRasterizeDescendants = shouldRasterize;
//    
//    NSLog(@"%@ rasterization for %@'s post: %@", shouldRasterize ? @"Enabling" : @"Disabling", post.name, postNode);
//    
//    [tableNode deselectRowAtIndexPath:indexPath animated:YES];
}

@end
