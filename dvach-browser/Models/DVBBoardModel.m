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
#import "DVBUrls.h"
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
    weakify(self);
    [_networking getThreadsWithBoard:_boardCode
                             andPage:_currentPage
                       andCompletion:^(NSDictionary *resultDict, NSError *error)
    {
        strongify(self);
        if (!self) { return; }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

            if (self.currentPage == 0) {
                self.threadsAlreadyLoaded = [@{} mutableCopy];
            }
            NSArray *threadsArray = resultDict[@"threads"];
            
            for (NSDictionary *thread in threadsArray) {
                if (!self.threadsAlreadyLoaded[thread[@"thread_num"]]) {
                    self.threadsAlreadyLoaded[thread[@"thread_num"]] = @"";
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
                                NSString *thumbPath = [NSString stringWithFormat:@"%@%@", [DVBUrls base], tmpThumbnail];
                                thread.thumbnail = thumbPath;
                            }
                        }

                        // Strip comment from useless words that we'll not see anyway
                        NSArray *commentArray = [thread.comment componentsSeparatedByString:@" "];

                        NSArray *titleArray = [thread.subject componentsSeparatedByString:@" "];

                        NSString *preparedComment = @"";

                        // If title auto-made from comment on server (/b/ - example) - mark it so
                        BOOL isTitleMadeFromComment = [DVBThread isTitle:thread.subject madeFromComment:thread.comment];

                        if ([thread.subject isEqualToString:@""] || isTitleMadeFromComment) {
                            preparedComment = [NSString stringWithFormat:@"%@ • ", [DVBThread threadTitleFromTitle:thread.subject andNum:thread.num andComment:thread.comment]];
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

                        [self.privateThreadsArray addObject:thread];
                    }
                    else {
                        NSLog(@"error while parsing threads: %@", parseError.localizedDescription);
                    }
                }
            }

            if (!self) { return; }
            
            NSArray *resultArr = [[NSArray alloc] initWithArray:self.privateThreadsArray];
            [self assignThreadsArrayFromWeak:resultArr];
            
            self.currentPage++;
            
            if (self.currentPage == self.maxPage) {
                self.currentPage = 0;
            }
            
            completion(resultArr, error);
        });
    }];
}

- (void)assignThreadsArrayFromWeak:(NSArray *)array
{
    _threadsArray = array;
}

- (void)reloadBoardWithViewWidth:(CGFloat)width andCompletion:(void (^)(NSArray *))completion
{
    _privateThreadsArray = [NSMutableArray array];
    _currentPage = 0;
    [self loadNextPageWithViewWidth:width
                      andCompletion:^(NSArray *threadsCompletion, NSError *error)
    {
        completion(threadsCompletion);
    }];
}

@end
