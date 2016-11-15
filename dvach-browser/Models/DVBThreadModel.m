//
//  DVBThreadModel.m
//  dvach-browser
//
//  Created by Andy on 20/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Mantle/Mantle.h>

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
    weakify(self);
    // Heavy work dispatched to a separate thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Load posts from DB
        [connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            strongify(self);
            if (!self) { return; }
            NSArray *arrayOfPosts = [transaction objectForKey:self.threadNum inCollection:DB_COLLECTION_THREADS];
            self.privatePostsArray = [arrayOfPosts mutableCopy];
            self.privateThumbImagesArray = [[self thumbImagesArrayForPostsArray:arrayOfPosts] mutableCopy];
            self.privateFullImagesArray = [[self fullImagesArrayForPostsArray:arrayOfPosts] mutableCopy];

            if (self.privatePostsArray.count != 0) {
                DVBPost *lastPost = (DVBPost *)self.privatePostsArray.lastObject;
                self.lastPostNum = lastPost.num;
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
    weakify(self);
    if (_boardCode && _threadNum) {
        [_networking getPostsWithBoard:_boardCode
                             andThread:_threadNum
                            andPostNum:_lastPostNum
                         andCompletion:^(id postsDictionary)
        {
            // Heavy work dispatched to a separate thread
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                strongify(self);
                if (!self) { return; }
                // NSLog(@"Work Dispatched");
                // Do heavy or time consuming work
                // Task 1: Read the data from sqlite
                // Task 2: Process the data with a flag to stop the process if needed (only if this takes very long and may be cancelled often).
//                if (strongSelf) {
                    NSMutableArray *postNumMutableArray = [@[] mutableCopy];
                    // If it's first load - do not include post
                    if (!self.lastPostNum) {
                        self.privatePostsArray = [@[] mutableCopy];
                        self.privateThumbImagesArray = [@[] mutableCopy];
                        self.privateFullImagesArray = [@[] mutableCopy];
                    } else {
                        // update dates to relevant values
                        for (DVBPost *earlierPost in self.privatePostsArray) {
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
                        if ((postIndexNumber == 0) && (self.lastPostNum)) {
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

                            NSAttributedString *attributedComment = [self.postPreparation commentWithMarkdownWithComments:comment];

                            post.comment = attributedComment;

                            [postNumMutableArray addObject:post.num];

                            NSMutableArray *repliesToArray = [self.postPreparation repliesToArrayForPost];

                            NSArray *files = postDictionary[@"files"];
                            NSMutableArray *singlePostPathesArrayMutable = [@[] mutableCopy];
                            NSMutableArray *singlePostThumbPathesArrayMutable = [@[] mutableCopy];

                            BOOL isTrafficEconomyEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_TRAFFIC_SAVINGS];
                            BOOL isInReviewModeOk = [[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_REVIEW_STATUS];

                            if (files && !isTrafficEconomyEnabled && isInReviewModeOk) {
                                for (NSDictionary *fileDictionary in files) {
                                    NSString *fullFileName = fileDictionary[@"path"];

                                    NSString *thumbPath = [[NSString alloc] initWithFormat:@"%@%@", [DVBUrls base], fileDictionary[@"thumbnail"]];

                                    [singlePostThumbPathesArrayMutable addObject:thumbPath];
                                    [self.privateThumbImagesArray addObject:thumbPath];

                                    NSString *picPath;
                                    BOOL isContainWebm = ([fullFileName rangeOfString:@".webm" options:NSCaseInsensitiveSearch].location != NSNotFound);

                                    // check webm or not
                                    if (isContainWebm) { // if contains .webm
                                        // make VLC webm link
                                        picPath = [[NSString alloc] initWithFormat:@"vlc://%@%@", [DVBUrls baseWithoutScheme], fullFileName];
                                    }
                                    else {               // if regular image
                                        picPath = [[NSString alloc] initWithFormat:@"%@%@", [DVBUrls base], fullFileName];
                                    }

                                    [singlePostPathesArrayMutable addObject:picPath];
                                    [self.privateFullImagesArray addObject:picPath];
                                }
                            }

                            post.repliesTo = repliesToArray;

                            post.thumbPathesArray = [singlePostThumbPathesArrayMutable copy];
                            singlePostThumbPathesArrayMutable = nil;

                            post.pathesArray = [singlePostPathesArrayMutable copy];
                            singlePostPathesArrayMutable = nil;

                            [self.privatePostsArray addObject:post];

                            postIndexNumber++;
                        } else {
                            NSLog(@"error: %@", error.localizedDescription);
                        }
                    }
                    
                    self.thumbImagesArray = self.privateThumbImagesArray;
                    self.fullImagesArray = self.privateFullImagesArray;
                    
                    self.postNumArray = postNumMutableArray;
                    
                    // array with almost all info - BUT without final ANSWERS array for every post
                    NSArray *semiResultArray = [self.privatePostsArray copy];
                    
                    NSMutableArray *semiResultMutableArray = [semiResultArray mutableCopy];
                    
                    NSUInteger currentPostIndex = 0;
                    
                    for (DVBPost *post in semiResultArray) {
                        NSMutableArray *delete = [NSMutableArray array];
                        for (NSString *replyTo in post.repliesTo) {
                            NSInteger index = [self.postNumArray indexOfObject:replyTo];
                            
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

                    [self assignPostsArrayFromWeak:semiResultMutableArray];
                    DVBPost *lastPost = (DVBPost *)[self.postsArray lastObject];
                    self.lastPostNum = lastPost.num;

                    if (self.postsArray.count == 0) {
                        [self dropPostsArray];

                        // back to main
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completion(self.postsArray);
                        });
                    } else {
                        [self writeToDbWithPosts:self.postsArray andThreadNum:self.threadNum andCompletion:^
                        {
                            // back to main
                            dispatch_async(dispatch_get_main_queue(), ^{
                                completion(self.postsArray);
                            });
                        }];
                    }


//                }
            });
        }];
    }
    else {
        NSLog(@"No Board code or Thread number");
        completion(nil);
    }
}

- (void)assignPostsArrayFromWeak:(NSArray *)array
{
    _postsArray = array;
}

- (void)dropPostsArray
{
    _postsArray = nil;
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
