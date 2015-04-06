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
#import "DVBPostObj.h"
#import "DVBPostPreparation.h"
#import "DVBBadPostStorage.h"
#import "DVBBadPost.h"
#import "DateFormatter.h"

@interface DVBThreadModel ()

@property (nonatomic, strong) NSString *boardCode;
@property (nonatomic, strong) NSString *threadNum;
@property (nonatomic, strong) NSMutableArray *privatePostsArray;
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
        _privatePostsArray = [NSMutableArray array];
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
            NSMutableArray *postsFullMutArray = [NSMutableArray array];
            
            _thumbImagesArray = [[NSMutableArray alloc] init];
            _fullImagesArray = [[NSMutableArray alloc] init];
            
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
                
                NSAttributedString *attributedComment = [_postPreparation commentWithMarkdownWithComments:comment];
                
                NSMutableArray *repliesToArray = [_postPreparation repliesToArrayForPost];
                
                NSDictionary *files = key[@"files"][0];
                
                NSString *thumbPath = [[NSMutableString alloc] init];
                NSString *picPath = [[NSMutableString alloc] init];
                
                
                if (files != nil)
                {
                    
                    // check webm or not
                    NSString *fullFileName = files[@"path"];
                    
                    thumbPath = [[NSString alloc] initWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, files[@"thumbnail"]];
                    
                    [_thumbImagesArray addObject:thumbPath];
                    
                    if ([fullFileName rangeOfString:@".webm" options:NSCaseInsensitiveSearch].location != NSNotFound)
                    {
                        // if contains .webm
                        
                        // make VLC webm link
                        picPath = [[NSString alloc] initWithFormat:@"vlc://%@%@/%@", DVACH_BASE_URL_WITHOUT_SCHEME, _boardCode, files[@"path"]];
                    }
                    else
                    {
                        // if not contains .webm - regular pic link
                        picPath = [[NSString alloc] initWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, files[@"path"]];
                    }
                    
                    [_fullImagesArray addObject:picPath];
                    
                }
                
                DVBPostObj *postObj = [[DVBPostObj alloc] initWithNum:num
                                                              subject:subject
                                                              comment:attributedComment
                                                                 path:picPath
                                                            thumbPath:thumbPath
                                                                 date:date
                                                              dateAgo:dateAgo
                                                            repliesTo:repliesToArray];
                [postsFullMutArray addObject:postObj];
                postObj = nil;
            }
            
            _postNumArray = postNumMutableArray;
            
            // array with almost all info - BUT without final ANSWERS array for every post
            NSArray *semiResultArray = [[NSArray alloc] initWithArray:postsFullMutArray];
            
            NSMutableArray *semiResultMutableArray = [semiResultArray mutableCopy];
            
            NSUInteger currentPostIndex = 0;
            
            for (DVBPostObj *post in semiResultArray) {
                NSMutableArray *delete = [NSMutableArray array];
                for (NSString *replyTo in post.repliesTo) {
                    NSInteger index = [_postNumArray indexOfObject:replyTo];
                    
                    if (index != NSNotFound) {
                        DVBPostObj *replyPost = semiResultMutableArray[index];
                        [replyPost.replies addObject:post];
                        // NSLog(@"added: %@ to post # %@", replyPost.num, post.num);
                    }
                    else {
                        [delete addObject:replyTo];
                    }
                }
                
                DVBPostObj *postForChangeReplyTo = semiResultMutableArray[currentPostIndex];
                for (NSString *replyTo in delete) {
                    [postForChangeReplyTo.repliesTo removeObject:replyTo];
                }
                [semiResultMutableArray setObject:postForChangeReplyTo
                               atIndexedSubscript:currentPostIndex];
                
                currentPostIndex++;
            }
            NSArray *resultArray = semiResultMutableArray;
            
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
    [_postsArray removeObjectAtIndex:index];
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
    NSMutableArray *thumbMutableArray = [NSMutableArray array];
    for (DVBPostObj *post in postsArray) {
        NSString *thumbPath = post.thumbPath;
        BOOL isThumbPathNotEmpty = ![thumbPath isEqualToString:@""];
        if (isThumbPathNotEmpty) {
            [thumbMutableArray addObject:thumbPath];
        }
    }
    NSArray *returnThumbsArray = thumbMutableArray;
    
    return returnThumbsArray;
}

- (NSArray *)fullImagesArrayForPostsArray:(NSArray *)postsArray
{
    NSMutableArray *fullImagesMutableArray = [NSMutableArray array];
    for (DVBPostObj *post in postsArray) {
        NSString *fullImagePath = post.path;
        BOOL isFullImagePathNotEmpty = ![fullImagePath isEqualToString:@""];
        if (isFullImagePathNotEmpty) {
            [fullImagesMutableArray addObject:fullImagePath];
        }
    }
    NSArray *returnFullImagesArray = fullImagesMutableArray;
    
    return returnFullImagesArray;
}

@end
