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

@interface DVBThreadModel ()

@property (nonatomic, strong) NSString *boardCode;
@property (nonatomic, strong) NSString *threadNum;
@property (nonatomic, strong) NSMutableArray *privatePostsArray;
@property (nonatomic, strong) DVBNetworking *networking;
@property (nonatomic, strong) DVBPostPreparation *postPreparation;
// storage for bad posts, marked on this specific device
@property (nonatomic, strong) DVBBadPostStorage *badPostsStorage;

@end

@implementation DVBThreadModel

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Need board code and thread num" reason:@"Use -[[DVBThreadModel alloc] initWithBoardCode:andThreadNum:]" userInfo:nil];
    
    return nil;
}

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
        _postPreparation = [[DVBPostPreparation alloc] init];
        
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
            
            NSMutableDictionary *resultDict = [postsDictionary mutableCopy];
            
            NSArray *threadsDict = resultDict[@"threads"];
            NSDictionary *postsArray = threadsDict[0];
            NSArray *posts2Array = postsArray[@"posts"];
            
            for (id key in posts2Array)
            {
                NSString *num = [key[@"num"] stringValue];
                
                // server gives me number but I need string
                NSString *tmpNumForPredicate = [key[@"num"] stringValue];
                
                //searching for bad posts
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.num contains[cd] %@", tmpNumForPredicate];
                NSArray *filtered = [_badPostsStorage.badPostsArray filteredArrayUsingPredicate:predicate];
                
                if ([filtered count] > 0)
                {
                    continue;
                }
                
                NSString *comment = key[@"comment"];
                NSString *subject = key[@"subject"];
                
                NSAttributedString *attributedComment = [_postPreparation commentWithMarkdownWithComments:comment];
                
                NSDictionary *files = [key[@"files"] objectAtIndex:0];
                
                NSMutableString *thumbPathMut;
                NSMutableString *picPathMut;
                
                if (files != nil)
                {
                    
                    // check webm or not
                    NSString *fullFileName = files[@"path"];
                    if ([fullFileName rangeOfString:@".webm" options:NSCaseInsensitiveSearch].location != NSNotFound)
                    {
                        
                        // if contains .webm
                        thumbPathMut = [[NSMutableString alloc] initWithString:@""];
                        picPathMut = [[NSMutableString alloc] initWithString:@""];
                        
                    }
                    else
                    {
                        
                        // if not contains .webm
                        
                        // rewrite in future
                        NSMutableString *fullThumbPath = [[NSMutableString alloc] initWithString:DVACH_BASE_URL];
                        [fullThumbPath appendString:self.boardCode];
                        [fullThumbPath appendString:@"/"];
                        [fullThumbPath appendString:[files objectForKey:@"thumbnail"]];
                        thumbPathMut = fullThumbPath;
                        fullThumbPath = nil;
                        
                        // rewrite in future
                        NSMutableString *fullPicPath = [[NSMutableString alloc] initWithString:DVACH_BASE_URL];
                        [fullPicPath appendString:_boardCode];
                        [fullPicPath appendString:@"/"];
                        [fullPicPath appendString:[files objectForKey:@"path"]];
                        picPathMut = fullPicPath;
                        fullPicPath = nil;
                        
                        [_thumbImagesArray addObject:thumbPathMut];
                        [_fullImagesArray addObject:picPathMut];
                        
                    }
                    
                }
                else
                {
                    // if there are no files - make blank file paths
                    thumbPathMut = [[NSMutableString alloc] initWithString:@""];
                    picPathMut = [[NSMutableString alloc] initWithString:@""];
                }
                NSString *thumbPath = thumbPathMut;
                NSString *picPath = picPathMut;
                
                DVBPostObj *postObj = [[DVBPostObj alloc] initWithNum:num
                                                              subject:subject
                                                              comment:attributedComment
                                                                 path:picPath
                                                            thumbPath:thumbPath];
                [postsFullMutArray addObject:postObj];
                postObj = nil;
            }
            
            NSArray *resultArr = [[NSArray alloc] initWithArray:postsFullMutArray];
            
            completion(resultArr);
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

@end
