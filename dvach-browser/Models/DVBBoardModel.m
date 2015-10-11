//
//  DVBBoardModel.m
//  dvach-browser
//
//  Created by Andy on 10/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Mantle/Mantle.h>

#import "DVBBoardModel.h"
#import "DVBNetworking.h"
#import "DVBConstants.h"
#import "DVBThread.h"

@interface DVBBoardModel ()

@property (nonatomic, strong) NSString *boardCode;
@property (nonatomic, assign) NSUInteger currentPage;
@property (nonatomic, assign) NSUInteger maxPage;
@property (nonatomic, strong) NSMutableArray *privateThreadsArray;
@property (nonatomic, strong) DVBNetworking *networking;
/// Dictionary of threads already showed in current cycle
@property (nonatomic, strong) NSMutableDictionary *threadsAlreadyLoaded;

@end

@implementation DVBBoardModel

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Need board code" reason:@"Use -[[DVBBoardModel alloc] initWithBoardCode:]" userInfo:nil];
    
    return nil;
}

- (instancetype)initWithBoardCode:(NSString *)boardCode andMaxPage:(NSUInteger)maxPage
{
    self = [super init];
    if (self) {
        _boardCode = boardCode;
        _maxPage = maxPage;
        _networking = [[DVBNetworking alloc] init];
       _privateThreadsArray = [@[] mutableCopy];
    }
    
    return self;
}

- (void)loadNextPageWithCompletion:(void (^)(NSArray *, NSError *))completion
{
    [_networking getThreadsWithBoard:_boardCode
                             andPage:_currentPage
                       andCompletion:^(NSDictionary *resultDict, NSError *error)
    {
        if (_currentPage == 0) {
            _threadsAlreadyLoaded = [@{} mutableCopy];
        }
        NSArray *threadsArray = resultDict[@"threads"];
        
        for (NSDictionary *thread in threadsArray) {
            if (!_threadsAlreadyLoaded[thread[@"thread_num"]]) {
                _threadsAlreadyLoaded[thread[@"thread_num"]] = @"";
                NSArray *threadPosts = thread[@"posts"];

                NSError *parseError;

                NSDictionary *threadDict = [threadPosts firstObject];

                DVBThread *thread = [MTLJSONAdapter modelOfClass:DVBThread.class
                                          fromJSONDictionary:threadDict
                                                       error:&error];

                if (!parseError) {

                    thread.postsCount = [[NSNumber alloc] initWithInteger:([threadPosts count] + thread.postsCount.integerValue)];

                    NSString *tmpThumbnail = threadDict[@"files"][0][@"thumbnail"];

                    if (threadDict[@"files"][0][@"thumbnail"]) {
                        NSString *thumbPath = [NSString stringWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, tmpThumbnail];
                        thread.thumbnail = thumbPath;
                    }
                    [_privateThreadsArray addObject:thread];
                }
                else {
                    NSLog(@"error while parsing threads: %@", parseError.localizedDescription);
                }
            }
        }
        
        NSArray *resultArr = [[NSArray alloc] initWithArray:_privateThreadsArray];
        
        _threadsArray = resultArr;
        
        _currentPage++;
        
        if (_currentPage == _maxPage) {
            _currentPage = 0;
        }
        
        completion(resultArr, error);
    }];
}

- (void)reloadBoardWithCompletion:(void (^)(NSArray *))completion {
    _privateThreadsArray = [NSMutableArray array];
    _currentPage = 0;
    [self loadNextPageWithCompletion:^(NSArray *threadsCompletion, NSError *error) {
        completion(threadsCompletion);
    }];
}

@end
