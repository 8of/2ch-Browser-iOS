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
#import "DVBBadPostStorage.h"
#import "DVBBadPost.h"
#import "DateFormatter.h"

@interface DVBThreadModel ()

@property (nonatomic, strong) NSString *boardCode;
@property (nonatomic, strong) NSString *threadNum;
@property (nonatomic, strong) NSMutableArray *privatePostsArray;
@property (nonatomic, strong) NSMutableArray *privateThumbImagesArray;
@property (nonatomic, strong) NSMutableArray *privateFullImagesArray;
@property (nonatomic, strong) DVBNetworking *networking;
@property (nonatomic, strong) DVBPostPreparation *postPreparation;
// storage for bad posts, marked on this specific device
@property (nonatomic, strong) DVBBadPostStorage *badPostsStorage;
@property (nonatomic, strong) NSArray *postNumArray;

@end

@implementation DVBThreadModel
/*
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Need board code and thread num" reason:@"Use -[[DVBThreadModel alloc] initWithBoardCode:andThreadNum:]" userInfo:nil];
    
    return nil;
}
*/
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
        
        /**
         Handling bad posts on this device
         */
        _badPostsStorage = [[DVBBadPostStorage alloc] init];
        NSString *badPostsPath = [_badPostsStorage badPostsArchivePath];
        
        _badPostsStorage.badPostsArray = [NSKeyedUnarchiver unarchiveObjectWithFile:badPostsPath];
        if (!_badPostsStorage.badPostsArray)
        {
            _badPostsStorage.badPostsArray = [[NSMutableArray alloc] initWithObjects:nil];
        }
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
            
            for (id key in posts2Array)
            {
                NSString *num = [key[@"num"] stringValue];
                
                [postNumMutableArray addObject:num];
                
                // server gives me number but I need string
                NSString *tmpNumForPredicate = [key[@"num"] stringValue];
                
                //searching for bad posts
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.num contains[cd] %@", tmpNumForPredicate];
                NSArray *filtered = [_badPostsStorage.badPostsArray filteredArrayUsingPredicate:predicate];
                
                if ([filtered count] > 0) {
                    continue;
                }
                
                NSString *comment = key[@"comment"];
                NSString *subject = key[@"subject"];
                
                NSInteger timestamp = [key[@"timestamp"] integerValue];
                NSString *date = key[@"date"];
                NSString *dateAgo = [DateFormatter dateFromTimestamp:timestamp];
                
                NSString *name = key[@"name"];
                NSString *nameForPost = [_postPreparation cleanPosterNameWithHtmlPosterName:name];
                
                NSString *email = key[@"email"];
                BOOL isSage = [_postPreparation isPostContaintSageWithEmail:email];
                
                NSAttributedString *attributedComment = [_postPreparation commentWithMarkdownWithComments:comment];
                
                NSMutableArray *repliesToArray = [_postPreparation repliesToArrayForPost];
                
                NSDictionary *files = key[@"files"][0];
                
                NSString *thumbPath = [[NSMutableString alloc] init];
                NSString *picPath = [[NSMutableString alloc] init];
                
                DVBPostMediaType mediaType = noMedia;
                
                if (files != nil)
                {
                    NSString *fullFileName = files[@"path"];
                    
                    mediaType = [_postPreparation mediaTypeInsidePostWithPicPath:fullFileName];
                    
                    thumbPath = [[NSString alloc] initWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, files[@"thumbnail"]];
                    
                    [_privateThumbImagesArray addObject:thumbPath];
                    
                    // check webm or not
                    if (mediaType == webm) // if contains .webm
                    {
                        // make VLC webm link
                        picPath = [[NSString alloc] initWithFormat:@"vlc://%@%@/%@", DVACH_BASE_URL_WITHOUT_SCHEME, _boardCode, fullFileName];
                    }
                    else                    // if regular image
                    {
                        picPath = [[NSString alloc] initWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, fullFileName];
                    }
                    
                    [_privateFullImagesArray addObject:picPath];
                }
                
                DVBPost *post = [[DVBPost alloc] initWithNum:num
                                                        subject:subject
                                                        comment:attributedComment
                                                           path:picPath
                                                      thumbPath:thumbPath
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
    else
    {
        NSLog(@"No Board code or Thread number");
        completion(nil);
    }
}

- (void)flagPostWithIndex:(NSUInteger)index
        andFlaggedPostNum:(NSString *)flaggedPostNum
      andOpAlreadyDeleted:(BOOL)opAlreadyDeleted
{
    [_privatePostsArray removeObjectAtIndex:index];
    _postsArray = _privatePostsArray;
    BOOL threadOrNot = NO;
    if ((index == 0)&&(!opAlreadyDeleted))
    {
        threadOrNot = YES;
        opAlreadyDeleted = YES;
    }
    DVBBadPost *tmpBadPost = [[DVBBadPost alloc] initWithNum:flaggedPostNum
                                                 threadOrNot:threadOrNot];
    [_badPostsStorage.badPostsArray addObject:tmpBadPost];
    BOOL badPostsSavingSuccess = [_badPostsStorage saveChanges];
    if (badPostsSavingSuccess)
    {
        NSLog(@"Bad Posts saved to file");
    }
    else
    {
        NSLog(@"Couldn't save bad posts to file");
    }
}

- (NSArray *)thumbImagesArrayForPostsArray:(NSArray *)postsArray
{
    _privateThumbImagesArray = [NSMutableArray array];
    for (DVBPost *post in postsArray) {
        NSString *thumbPath = post.thumbPath;
        BOOL isThumbPathNotEmpty = ![thumbPath isEqualToString:@""];
        if (isThumbPathNotEmpty) {
            [_privateThumbImagesArray addObject:thumbPath];
        }
    }
    _thumbImagesArray = _privateThumbImagesArray;
    
    return _thumbImagesArray;
}

- (NSArray *)fullImagesArrayForPostsArray:(NSArray *)postsArray
{
    _privateFullImagesArray = [NSMutableArray array];
    for (DVBPost *post in postsArray) {
        NSString *fullImagePath = post.path;
        BOOL isFullImagePathNotEmpty = ![fullImagePath isEqualToString:@""];
        if (isFullImagePathNotEmpty) {
            [_privateFullImagesArray addObject:fullImagePath];
        }
    }
   _fullImagesArray = _privateFullImagesArray;
    
    return _fullImagesArray;
}

@end
