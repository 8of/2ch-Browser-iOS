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
                         andCompletion:^(NSDictionary *postsDictionary)
        {
            _privatePostsArray = [NSMutableArray array];
            _privateThumbImagesArray = [NSMutableArray array];
            _privateFullImagesArray = [NSMutableArray array];
            
            
            NSMutableArray *postNumMutableArray = [[NSMutableArray alloc] init];
            
            NSMutableDictionary *resultDict = [postsDictionary mutableCopy];

            NSArray *posts2Array = resultDict[@"threads"][0][@"posts"];
            
            for (NSDictionary *postDictionary in posts2Array) {

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

- (void)getPostWithBoardCode:(NSString *)board andThread:(NSString *)thread andPostNum:(NSString *)postNum andCompletion:(void (^)(DVBPost *))completion
{
    [_networking getPostWithBoardCode:board andThread:thread andPostNum:postNum andCompletion:^(NSArray *networkCompletion) {
        if (networkCompletion) {

            NSError *error;
            if (error) {
                completion(nil);
            }
            if (networkCompletion.count > 0) {

                NSDictionary *postDictionary = [networkCompletion firstObject];
                DVBPost *post = [MTLJSONAdapter modelOfClass:DVBPost.class
                                          fromJSONDictionary:postDictionary
                                                       error:&error];

                NSString *comment = postDictionary[@"comment"];

                NSAttributedString *attributedComment = attributedComment = [_postPreparation commentWithMarkdownWithComments:comment];

                post.comment = attributedComment;

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

                post.thumbPathesArray = [singlePostThumbPathesArrayMutable copy];
                singlePostThumbPathesArrayMutable = nil;

                post.pathesArray = [singlePostPathesArrayMutable copy];
                singlePostPathesArrayMutable = nil;

                completion(post);
            }
            else {
                completion(nil);
            }
        }
        else {
            completion(nil);
        }
    }];
}

@end
