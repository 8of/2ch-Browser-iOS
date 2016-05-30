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

#import "DVBThreadTableViewCell.h"

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

- (void)loadNextPageWithViewWidth:(CGFloat)width andCompletion:(void (^)(NSArray *, NSError *))completion
{
    [_networking getThreadsWithBoard:_boardCode
                             andPage:_currentPage
                       andCompletion:^(NSDictionary *resultDict, NSError *error)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

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
                                                           error:&parseError];

                    if (!parseError) {

                        thread.postsCount = [[NSNumber alloc] initWithInteger:([threadPosts count] + thread.postsCount.integerValue)];

                        BOOL isInReviewModeOk = [[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_REVIEW_STATUS];

                        if (threadDict[@"files"] && isInReviewModeOk) {
                            NSArray *files = threadDict[@"files"];
                            if (files.count > 0) {
                                NSString *tmpThumbnail = threadDict[@"files"][0][@"thumbnail"];
                                NSString *thumbPath = [NSString stringWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, tmpThumbnail];
                                thread.thumbnail = thumbPath;
                            }
                        }
                        
                        NSString *preparedComment = @"";

                        // Strip comment from useless words that we'll not see anyway
                        NSArray *commentArray = [thread.comment componentsSeparatedByString:@" "];

                        // Need to rethink, doesn't look very good
                        NSString *title = thread.subject;
                        NSArray *titleArray = [title componentsSeparatedByString:@" "];
                        if ([title isEqualToString:@""]) {
                            preparedComment = [NSString stringWithFormat:@"%@ • ", thread.num];
                        } else {
                            for (NSString *nextPart in titleArray) {
                                NSString *newCommentLike = [preparedComment stringByAppendingFormat:@"%@ ", nextPart];
                                if ([DVBThreadTableViewCell goodFitWithViewWidth:width andString:newCommentLike]) {
                                    preparedComment = newCommentLike;
                                } else {
                                    break;
                                }
                            }
                            NSString *withDotPart = [NSString stringWithFormat:@"%@ • ", preparedComment];
                            if ([DVBThreadTableViewCell goodFitWithViewWidth:width andString:withDotPart]) {
                                preparedComment = withDotPart;
                            }
                        }

                        for (NSString *nextPart in commentArray) {
                            NSString *newCommentLike = [preparedComment stringByAppendingFormat:@"%@ ", nextPart];
                            if ([DVBThreadTableViewCell goodFitWithViewWidth:width andString:newCommentLike]) {
                                preparedComment = newCommentLike;
                            } else {
                                break;
                            }
                        }
                        thread.comment = preparedComment;

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
        });
    }];
}

- (void)reloadBoardWithViewWidth:(CGFloat)width andCompletion:(void (^)(NSArray *))completion {
    _privateThreadsArray = [NSMutableArray array];
    _currentPage = 0;
    [self loadNextPageWithViewWidth:width
                      andCompletion:^(NSArray *threadsCompletion, NSError *error)
    {
        completion(threadsCompletion);
    }];
}

@end
