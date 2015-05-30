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
       _privateThreadsArray = [NSMutableArray array];
    }
    
    return self;
}

- (void)loadNextPageWithCompletion:(void (^)(NSArray *))completion
{
    [_networking getThreadsWithBoard:_boardCode
                             andPage:_currentPage
                       andCompletion:^(NSDictionary *resultDict)
    {
        NSArray *threadsArray = resultDict[@"threads"];
        
        for (id thread in threadsArray) {
            NSError *error;

            NSDictionary *threadDict = [thread[@"posts"] firstObject];

            DVBThread *thread = [MTLJSONAdapter modelOfClass:DVBThread.class
                                      fromJSONDictionary:threadDict
                                                   error:&error];

            if (!error) {
                NSString *tmpThumbnail = threadDict[@"files"][0][@"thumbnail"];

                if (threadDict[@"files"][0][@"thumbnail"]) {
                    NSString *thumbPath = [NSString stringWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, tmpThumbnail];
                    thread.thumbnail = thumbPath;
                }
                [_privateThreadsArray addObject:thread];
            }
            else {
                NSLog(@"error: %@", error.localizedDescription);
            }
        }
        
        NSArray *resultArr = [[NSArray alloc] initWithArray:_privateThreadsArray];
        
        _threadsArray = resultArr;
        
        _currentPage++;
        
        if (_currentPage == _maxPage) {
            _currentPage = 0;
        }
        
        completion(resultArr);
        
    }];
}

- (void)reloadBoardWithCompletion:(void (^)(NSArray *))completion {
    _privateThreadsArray = [NSMutableArray array];
    _currentPage = 0;
    [self loadNextPageWithCompletion:^(NSArray *threadsCompletion) {
        completion(threadsCompletion);
    }];
}


@end
