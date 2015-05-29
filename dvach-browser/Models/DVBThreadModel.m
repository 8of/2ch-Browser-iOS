//
//  DVBThreadModel.m
//  dvach-browser
//
//  Created by Andy on 20/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

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
    if (self)
    {
        _boardCode = boardCode;
        _threadNum = threadNum;
        _networking = [[DVBNetworking alloc] init];
        _postPreparation = [[DVBPostPreparation alloc] initWithBoardId:boardCode andThreadId:threadNum];
    }
    
    return self;
}

- (void)reloadThreadWithCompletion:(void (^)(NSArray *))completion
{
    if (_boardCode && _threadNum)
    {
        [_networking getPostsWithBoard:_boardCode
                             andThread:_threadNum
                         andCompletion:^(NSDictionary *postsDictionary)
        {
            _privatePostsArray = [NSMutableArray array];
            _privateThumbImagesArray = [NSMutableArray array];
            _privateFullImagesArray = [NSMutableArray array];
            
            
            NSMutableArray *postNumMutableArray = [[NSMutableArray alloc] init];
            
            NSMutableDictionary *resultDict = [postsDictionary mutableCopy];
            
            NSArray *threadsDict = resultDict[@"threads"];
            NSDictionary *postsArray = threadsDict[0];
            NSArray *posts2Array = postsArray[@"posts"];
            
            for (id key in posts2Array) {
                NSString *num = [key[@"num"] stringValue];
                
                [postNumMutableArray addObject:num];
                
                NSString *comment;
                // Check comment for bad symbols
                if ([key[@"comment"] rangeOfString:@"ررً"].location == NSNotFound) {
                    comment = key[@"comment"];
                }
                else {
                    NSString *brokenStringHere = NSLocalizedString(@"Пост содержит запрещённые символы", @"Вставка в пост о том, что он содержит сломаные символы");
                    comment = brokenStringHere;
                }

                NSString *subject;
                // Check subject for bad symbols
                if ([key[@"subject"] rangeOfString:@"ررً"].location == NSNotFound) {
                    subject = key[@"subject"];
                }
                
                NSInteger timestamp = [key[@"timestamp"] integerValue];
                NSString *date = key[@"date"];
                NSString *dateAgo = [DateFormatter dateFromTimestamp:timestamp];
                
                NSString *name = key[@"name"];
                NSString *nameForPost = [_postPreparation cleanPosterNameWithHtmlPosterName:name];
                
                NSString *email = key[@"email"];
                BOOL isSage = [_postPreparation isPostContaintSageWithEmail:email];
                
                NSAttributedString *attributedComment = [_postPreparation commentWithMarkdownWithComments:comment];
                
                NSMutableArray *repliesToArray = [_postPreparation repliesToArrayForPost];

                NSArray *files = key[@"files"];

                NSDictionary *files_first = key[@"files"][0];
                
                NSString *thumbPath = [[NSMutableString alloc] init];
                NSString *picPath = [[NSMutableString alloc] init];
                
                DVBPostMediaType mediaType = noMedia;

                NSMutableArray *singlePostPathesArrayMutable = [@[] mutableCopy];
                NSMutableArray *singlePostThumbPathesArrayMutable = [@[] mutableCopy];

                // new approach
                if (files) {
                    for (NSDictionary *fileDictionary in files) {
                        NSString *fullFileName = fileDictionary[@"path"];

                        mediaType = [_postPreparation mediaTypeInsidePostWithPicPath:fullFileName];

                        thumbPath = [[NSString alloc] initWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, fileDictionary[@"thumbnail"]];

                        [singlePostThumbPathesArrayMutable addObject:thumbPath];
                        [_privateThumbImagesArray addObject:thumbPath];

                        // check webm or not
                        if (mediaType == webm) { // if contains .webm
                            // make VLC webm link
                            picPath = [[NSString alloc] initWithFormat:@"vlc://%@%@/%@", DVACH_BASE_URL_WITHOUT_SCHEME, _boardCode, fullFileName];
                        }
                        else {                    // if regular image
                            picPath = [[NSString alloc] initWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, fullFileName];
                        }

                        [singlePostPathesArrayMutable addObject:picPath];
                        [_privateFullImagesArray addObject:picPath];
                    }
                }

                // old approach
                if (files_first) {
                    NSString *fullFileName = files_first[@"path"];
                    
                    mediaType = [_postPreparation mediaTypeInsidePostWithPicPath:fullFileName];
                    
                    thumbPath = [[NSString alloc] initWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, files_first[@"thumbnail"]];
                    
                    // check webm or not
                    if (mediaType == webm) { // if contains .webm
                        // make VLC webm link
                        picPath = [[NSString alloc] initWithFormat:@"vlc://%@%@/%@", DVACH_BASE_URL_WITHOUT_SCHEME, _boardCode, fullFileName];
                    }
                    else {                   // if regular image
                        picPath = [[NSString alloc] initWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, fullFileName];
                    }
                }

                NSArray *pathesArray = [singlePostPathesArrayMutable copy];
                NSArray *thumbPathesArray = [singlePostThumbPathesArrayMutable copy];

                // If post have multiple media attachments - just drop "old" full-thumb-pathes
                if ([pathesArray count] > 1) {
                    picPath = @"";
                    thumbPath = @"";
                    mediaType = noMedia;
                }
                
                DVBPost *post = [[DVBPost alloc]    initWithNum:num
                                                        subject:subject
                                                        comment:attributedComment
                                                           path:picPath
                                                      thumbPath:thumbPath
                                                    pathesArray:pathesArray
                                               thumbPathesArray:thumbPathesArray
                                                        date:date
                                                        dateAgo:dateAgo
                                                      repliesTo:repliesToArray
                                                      mediaType:mediaType
                                                           name:nameForPost
                                                           sage:isSage];

                [_privatePostsArray addObject:post];
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

@end
