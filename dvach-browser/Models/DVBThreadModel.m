//
//  DVBThreadModel.m
//  dvach-browser
//
//  Created by Andy on 20/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Mantle/Mantle.h>

#import "DVBThreadModel.h"
#import "DVBNetworking.h"
#import "DVBConstants.h"
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

@end

@implementation DVBThreadModel

- (instancetype)initWithBoardCode:(NSString *)boardCode
                     andThreadNum:(NSString *)threadNum
{
    self = [super init];
    if (self) {
        _boardCode = boardCode;
        _threadNum = threadNum;
        _networking = [[DVBNetworking alloc] init];
        _postPreparation = [[DVBPostPreparation alloc] initWithBoardId:boardCode andThreadId:threadNum];
    }
    
    return self;
}

- (void)reloadThreadWithCompletion:(void (^)(NSArray *))completion
{
    if (_boardCode && _threadNum) {
        [_networking getPostsWithBoard:_boardCode
                             andThread:_threadNum
                            andPostNum:_lastPostNum
                         andCompletion:^(id postsDictionary)
        {
            // If it's first load - do not include post
            if (!_lastPostNum) {
                _privatePostsArray = [NSMutableArray array];
                _privateThumbImagesArray = [NSMutableArray array];
                _privateFullImagesArray = [NSMutableArray array];
            } else {
                // update dates to rlevan values
                for (DVBPost *earlierPost in _privatePostsArray) {
                    [earlierPost updateDateAgo];
                }
            }
            
            NSMutableArray *postNumMutableArray = [[NSMutableArray alloc] init];

            NSArray *posts2Array;

            if ([postsDictionary isKindOfClass:[NSDictionary class]]) {
                posts2Array = postsDictionary[@"threads"][0][@"posts"];
            }
            else {
                posts2Array = (NSArray *)postsDictionary;
            }

            NSInteger postIndexNumber = 0;
            
            for (NSDictionary *postDictionary in posts2Array) {
                // Check if currently loading not the entire thread from the sratch but only from specific post
                // just skip first element because it will be the same as the last element from previous loading
                if ((postIndexNumber == 0) && (_lastPostNum)) {
                    postIndexNumber++;
                    continue;
                }

                NSError *error;

                DVBPost *post = [MTLJSONAdapter modelOfClass:DVBPost.class
                                          fromJSONDictionary:postDictionary
                                                       error:&error];

                if (!error) {
                    NSString *comment = postDictionary[@"comment"];

                    if ([comment rangeOfString:@"ررً"].location == NSNotFound) {
                    }
                    else {
                        NSString *brokenStringHere = NSLocalizedString(@"Пост содержит запрещённые символы", @"Вставка в пост о том, что он содержит сломаные символы");
                        comment = brokenStringHere;
                    }

                    NSAttributedString *attributedComment = attributedComment = [_postPreparation commentWithMarkdownWithComments:comment];

                    post.comment = attributedComment;

                    [postNumMutableArray addObject:post.num];

                    NSMutableArray *repliesToArray = [_postPreparation repliesToArrayForPost];

                    NSArray *files = postDictionary[@"files"];
                    NSMutableArray *singlePostPathesArrayMutable = [@[] mutableCopy];
                    NSMutableArray *singlePostThumbPathesArrayMutable = [@[] mutableCopy];

                    if (files) {
                        for (NSDictionary *fileDictionary in files) {
                            NSString *fullFileName = fileDictionary[@"path"];

                            NSString *thumbPath = [[NSString alloc] initWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, fileDictionary[@"thumbnail"]];

                            [singlePostThumbPathesArrayMutable addObject:thumbPath];
                            [_privateThumbImagesArray addObject:thumbPath];

                            NSString *picPath;
                            BOOL isContainWebm = ([fullFileName rangeOfString:@".webm" options:NSCaseInsensitiveSearch].location != NSNotFound);

                            // check webm or not
                            if (isContainWebm) { // if contains .webm
                                // make VLC webm link
                                picPath = [[NSString alloc] initWithFormat:@"vlc://%@%@/%@", DVACH_BASE_URL_WITHOUT_SCHEME, _boardCode, fullFileName];
                            }
                            else {               // if regular image
                                picPath = [[NSString alloc] initWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, fullFileName];
                            }

                            [singlePostPathesArrayMutable addObject:picPath];
                            [_privateFullImagesArray addObject:picPath];
                        }
                    }

                    post.repliesTo = repliesToArray;

                    post.thumbPathesArray = [singlePostThumbPathesArrayMutable copy];
                    singlePostThumbPathesArrayMutable = nil;

                    post.pathesArray = [singlePostPathesArrayMutable copy];
                    singlePostPathesArrayMutable = nil;

                    [_privatePostsArray addObject:post];

                    postIndexNumber++;
                }
                else {
                    NSLog(@"error: %@", error.localizedDescription);
                }

            }
            
            _thumbImagesArray = _privateThumbImagesArray;
            _fullImagesArray = _privateFullImagesArray;
            
            _postNumArray = postNumMutableArray;
            
            // array with almost all info - BUT without final ANSWERS array for every post
            NSArray *semiResultArray = [[NSArray alloc] initWithArray:_privatePostsArray];
            
            NSMutableArray *semiResultMutableArray = [semiResultArray mutableCopy];
            
            NSUInteger currentPostIndex = 0;
            
            for (DVBPost *post in semiResultArray) {
                NSMutableArray *delete = [NSMutableArray array];
                for (NSString *replyTo in post.repliesTo) {
                    NSInteger index = [_postNumArray indexOfObject:replyTo];
                    
                    if (index != NSNotFound) {
                        DVBPost *replyPost = semiResultMutableArray[index];
                        [replyPost.replies addObject:post];
                    }
                    else {
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
            NSArray *resultArray = semiResultMutableArray;
            
            _postsArray = resultArray;

            DVBPost *lastPost = (DVBPost *)[_postsArray lastObject];

            _lastPostNum = lastPost.num;
            
            completion(resultArray);
        }];
    }
    else {
        NSLog(@"No Board code or Thread number");
        completion(nil);
    }
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

@end
