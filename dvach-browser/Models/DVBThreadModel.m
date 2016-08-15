//
//  DVBThreadModel.m
//  dvach-browser
//
//  Created by Andy on 20/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Mantle/Mantle.h>

#import "DVBCommon.h"
#import "DVBConstants.h"
#import "DVBThreadModel.h"
#import "DVBDatabaseManager.h"
#import "DVBNetworking.h"
#import "DVBPost.h"
#import "DVBPostPreparation.h"
#import "DateFormatter.h"

@interface DVBThreadModel ()

@property (nonatomic, strong) NSString *boardCode;
@property (nonatomic, strong) NSString *threadNum;
@property (nonatomic, strong) NSMutableArray *privatePostsArray;
@property (nonatomic, strong) NSMutableArray *privateThumbImagesArray;
@property (nonatomic, strong) NSMutableArray *privateFullImagesArray;
@property (nonatomic, strong) DVBNetworking *networking;
@property (nonatomic, strong) DVBPostPreparation *postPreparation;
@property (nonatomic, strong) NSArray *postNumArray;
/// Id of the last post for loading from it
@property (nonatomic, strong) NSString *lastPostNum;

@property (nonatomic, strong) YapDatabase *database;

@end

@implementation DVBThreadModel

- (instancetype)initWithBoardCode:(NSString *)boardCode
                     andThreadNum:(NSString *)threadNum
{
    self = [super init];
    if (self) {
        DVBDatabaseManager *dbManager = [DVBDatabaseManager sharedDatabase];
        _database = dbManager.database;

        _boardCode = boardCode;
        _threadNum = threadNum;
        _networking = [[DVBNetworking alloc] init];
        _postPreparation = [[DVBPostPreparation alloc] initWithBoardId:boardCode
                                                           andThreadId:threadNum];
    }
    
    return self;
}

- (void)checkPostsInDbForThisThreadWithCompletion:(void (^)(NSArray *))completion
{
    YapDatabaseConnection *connection = [_database newConnection];

    // To prevent retain cycles call back by weak reference
    __weak typeof(self) weakSelf = self;

    // Heavy work dispatched to a separate thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        // Load posts from DB
        [connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {

            // Create strong reference to the weakSelf inside the block so that it´s not released while the block is running
            typeof(weakSelf) strongSelf = weakSelf;

            NSArray *arrayOfPosts = [transaction objectForKey:strongSelf.threadNum inCollection:DB_COLLECTION_THREADS];

            strongSelf.privatePostsArray = [arrayOfPosts mutableCopy];
            strongSelf.privateThumbImagesArray = [[strongSelf thumbImagesArrayForPostsArray:arrayOfPosts] mutableCopy];
            strongSelf.privateFullImagesArray = [[strongSelf fullImagesArrayForPostsArray:arrayOfPosts] mutableCopy];

            if (strongSelf.privatePostsArray.count != 0) {
                DVBPost *lastPost = (DVBPost *)strongSelf.privatePostsArray.lastObject;
                strongSelf.lastPostNum = lastPost.num;
            }

            _postsArray = arrayOfPosts;

            dispatch_async(dispatch_get_main_queue(), ^{
                completion([arrayOfPosts copy]);
            });
        }];
    });
}

- (void)reloadThreadWithCompletion:(void (^)(NSArray *))completion
{
    if (_boardCode && _threadNum) {
        [_networking getPostsWithBoard:_boardCode
                             andThread:_threadNum
                            andPostNum:_lastPostNum
                         andCompletion:^(id postsDictionary)
        {
            // To prevent retain cycles call back by weak reference
            __weak typeof(self) weakSelf = self;

            // Heavy work dispatched to a separate thread
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                // NSLog(@"Work Dispatched");
                // Do heavy or time consuming work
                // Task 1: Read the data from sqlite
                // Task 2: Process the data with a flag to stop the process if needed (only if this takes very long and may be cancelled often).

                // Create strong reference to the weakSelf inside the block so that it´s not released while the block is running
                typeof(weakSelf) strongSelf = weakSelf;
                if (strongSelf) {

                    NSMutableArray *postNumMutableArray = [@[] mutableCopy];

                    // If it's first load - do not include post
                    if (!strongSelf.lastPostNum) {
                        strongSelf.privatePostsArray = [@[] mutableCopy];
                        strongSelf.privateThumbImagesArray = [@[] mutableCopy];
                        strongSelf.privateFullImagesArray = [@[] mutableCopy];
                    } else {
                        // update dates to relevant values
                        for (DVBPost *earlierPost in strongSelf.privatePostsArray) {
                            [earlierPost updateDateAgo];
                            [postNumMutableArray addObject:earlierPost.num];
                            earlierPost.replies = [@[] mutableCopy];
                        }
                    }

                    NSArray *posts2Array;

                    if ([postsDictionary isKindOfClass:[NSDictionary class]]) {
                        posts2Array = postsDictionary[@"threads"][0][@"posts"];
                    } else {
                        posts2Array = (NSArray *)postsDictionary;
                    }

                    NSInteger postIndexNumber = 0;
                    
                    for (NSDictionary *postDictionary in posts2Array) {
                        // Check if currently loading not the entire thread from the sratch but only from specific post
                        // just skip first element because it will be the same as the last element from previous loading
                        if ((postIndexNumber == 0) && (strongSelf.lastPostNum)) {
                            postIndexNumber++;
                            continue;
                        }

                        NSError *error;

                        DVBPost *post = [MTLJSONAdapter modelOfClass:DVBPost.class
                                                  fromJSONDictionary:postDictionary
                                                               error:&error];

                        if (!error) {
                            NSString *comment = postDictionary[@"comment"];

                            // Fix bug with crash
                            if ([comment rangeOfString:@"ررً"].location != NSNotFound) {
                                NSString *brokenStringHere = NSLS(@"POST_BAD_SYMBOLS_IN_POST");
                                comment = brokenStringHere;
                            }

                            NSAttributedString *attributedComment = [strongSelf.postPreparation commentWithMarkdownWithComments:comment];

                            post.comment = attributedComment;

                            [postNumMutableArray addObject:post.num];

                            NSMutableArray *repliesToArray = [strongSelf.postPreparation repliesToArrayForPost];

                            NSArray *files = postDictionary[@"files"];
                            NSMutableArray *singlePostPathesArrayMutable = [@[] mutableCopy];
                            NSMutableArray *singlePostThumbPathesArrayMutable = [@[] mutableCopy];

                            BOOL isTrafficEconomyEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_TRAFFIC_SAVINGS];
                            BOOL isInReviewModeOk = [[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_REVIEW_STATUS];

                            if (files && !isTrafficEconomyEnabled && isInReviewModeOk) {
                                for (NSDictionary *fileDictionary in files) {
                                    NSString *fullFileName = fileDictionary[@"path"];

                                    NSString *thumbPath = [[NSString alloc] initWithFormat:@"%@%@/%@", DVACH_BASE_URL, strongSelf.boardCode, fileDictionary[@"thumbnail"]];

                                    [singlePostThumbPathesArrayMutable addObject:thumbPath];
                                    [strongSelf.privateThumbImagesArray addObject:thumbPath];

                                    NSString *picPath;
                                    BOOL isContainWebm = ([fullFileName rangeOfString:@".webm" options:NSCaseInsensitiveSearch].location != NSNotFound);

                                    // check webm or not
                                    if (isContainWebm) { // if contains .webm
                                        // make VLC webm link
                                        picPath = [[NSString alloc] initWithFormat:@"vlc://%@%@/%@", DVACH_BASE_URL_WITHOUT_SCHEME, strongSelf.boardCode, fullFileName];
                                    }
                                    else {               // if regular image
                                        picPath = [[NSString alloc] initWithFormat:@"%@%@/%@", DVACH_BASE_URL, strongSelf.boardCode, fullFileName];
                                    }

                                    [singlePostPathesArrayMutable addObject:picPath];
                                    [strongSelf.privateFullImagesArray addObject:picPath];
                                }
                            }

                            post.repliesTo = repliesToArray;

                            post.thumbPathesArray = [singlePostThumbPathesArrayMutable copy];
                            singlePostThumbPathesArrayMutable = nil;

                            post.pathesArray = [singlePostPathesArrayMutable copy];
                            singlePostPathesArrayMutable = nil;

                            [strongSelf.privatePostsArray addObject:post];

                            postIndexNumber++;
                        } else {
                            NSLog(@"error: %@", error.localizedDescription);
                        }
                    }
                    
                    strongSelf.thumbImagesArray = strongSelf.privateThumbImagesArray;
                    strongSelf.fullImagesArray = strongSelf.privateFullImagesArray;
                    
                    strongSelf.postNumArray = postNumMutableArray;
                    
                    // array with almost all info - BUT without final ANSWERS array for every post
                    NSArray *semiResultArray = [strongSelf.privatePostsArray copy];
                    
                    NSMutableArray *semiResultMutableArray = [semiResultArray mutableCopy];
                    
                    NSUInteger currentPostIndex = 0;
                    
                    for (DVBPost *post in semiResultArray) {
                        NSMutableArray *delete = [NSMutableArray array];
                        for (NSString *replyTo in post.repliesTo) {
                            NSInteger index = [strongSelf.postNumArray indexOfObject:replyTo];
                            
                            if (index != NSNotFound) {
                                DVBPost *replyPost = semiResultMutableArray[index];
                                [replyPost.replies addObject:post];
                            } else {
                                [delete addObject:replyTo];
                            }
                        }
                        
                        DVBPost *postForChangeReplyTo = semiResultMutableArray[currentPostIndex];
                        for (NSString *replyTo in delete) {
                            [postForChangeReplyTo.repliesTo removeObject:replyTo];
                        }
                        [semiResultMutableArray setObject:postForChangeReplyTo
                                       atIndexedSubscript:currentPostIndex];
                        
                        currentPostIndex++;
                    }

                    _postsArray = semiResultMutableArray;
                    DVBPost *lastPost = (DVBPost *)[strongSelf.postsArray lastObject];
                    strongSelf.lastPostNum = lastPost.num;

                    if (_postsArray.count == 0) {
                        _postsArray = nil;

                        // back to main
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(strongSelf.postsArray);
                        });
                    } else {
                        [self writeToDbWithPosts:_postsArray andThreadNum:_threadNum andCompletion:^
                        {
                            // back to main
                            dispatch_async(dispatch_get_main_queue(), ^{
                                completion(strongSelf.postsArray);
                            });
                        }];
                    }


                }
            });
        }];
    }
    else {
        NSLog(@"No Board code or Thread number");
        completion(nil);
    }
}

/// Check connection
- (BOOL)isConnectionAvailable
{
    return [_networking getNetworkStatus];
}

- (void)reportThreadWithBoardCode:(NSString *)board andThread:(NSString *)thread andComment:(NSString *)comment
{
    [_networking reportThreadWithBoardCode:board
                                 andThread:thread
                                andComment:comment];
}

- (NSArray *)thumbImagesArrayForPostsArray:(NSArray *)postsArray
{
    _privateThumbImagesArray = [@[] mutableCopy];
    for (DVBPost *post in postsArray) {
        NSArray *postThumbsArray = post.thumbPathesArray;

        for (NSString *thumbPath in postThumbsArray) {
            [_privateThumbImagesArray addObject:thumbPath];
        }
    }
    _thumbImagesArray = _privateThumbImagesArray;
    
    return _thumbImagesArray;
}

- (NSArray *)fullImagesArrayForPostsArray:(NSArray *)postsArray
{
    _privateFullImagesArray = [@[] mutableCopy];
    for (DVBPost *post in postsArray) {
        NSArray *postThumbsArray = post.pathesArray;

        for (NSString *thumbPath in postThumbsArray) {
            [_privateFullImagesArray addObject:thumbPath];
        }
    }
   _fullImagesArray = _privateFullImagesArray;
    
    return _fullImagesArray;
}

#pragma mark - DB

- (void)writeToDbWithPosts:(NSArray *)posts andThreadNum:(NSString *)threadNumb andCompletion:(void (^)(void))callback
{
    // Get a connection to the database (can have multiple for concurrency)
    YapDatabaseConnection *connection = [_database newConnection];

    // Add an object
    [connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:posts forKey:threadNumb inCollection:DB_COLLECTION_THREADS];

        callback();
    }];
}

@end
