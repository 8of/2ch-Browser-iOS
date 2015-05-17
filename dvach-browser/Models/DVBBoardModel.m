//
//  DVBBoardModel.m
//  dvach-browser
//
//  Created by Andy on 10/03/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import "DVBBoardModel.h"
#import "DVBNetworking.h"
#import "DVBConstants.h"
#import "DVBThread.h"
#import "NSString+HTML.h"
#import "DateFormatter.h"

@interface DVBBoardModel ()

@property (nonatomic, strong) NSString *boardCode;
@property (nonatomic, assign) NSUInteger currentPage;
@property (nonatomic, assign) NSUInteger maxPage;
@property (nonatomic, strong) NSMutableArray *privateThreadsArray;
@property (nonatomic, strong) DVBNetworking *networking;

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
       _privateThreadsArray = [NSMutableArray array];
    }
    
    return self;
}

- (void)loadNextPageWithCompletion:(void (^)(NSArray *))completion
{
    [_networking getThreadsWithBoard:_boardCode
                             andPage:_currentPage
                       andCompletion:^(NSDictionary *resultDict)
    {
        
        NSDictionary *threadsDict = [resultDict objectForKey:@"threads"];
        
        for (id key in threadsDict)
        {
            // Count number of last posts because posts_count isn't accurate - it's not count last posts
            NSArray *lastPosts = [key objectForKey:@"posts"];
            NSInteger lastpostsCount = [lastPosts count];

            NSDictionary *opPost = [[key objectForKey:@"posts"] objectAtIndex:0];
            
            // very important note: unlikely in other NUM keys in other JSON answers - here server answers STRING SOMETIMES and NOT ONLY NUMBER
            NSString *num = [opPost objectForKey:@"num"];
            
            NSString *subject = [opPost objectForKey:@"subject"];
            NSString *comment = [opPost objectForKey:@"comment"];
            comment = [comment stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
            comment = [comment stringByConvertingHTMLToPlainText];
            NSNumber *filesCount = [opPost objectForKey:@"files_count"];
            NSNumber *postsCount = [opPost objectForKey:@"posts_count"];

            NSInteger totalPostsCount = [postsCount integerValue] + lastpostsCount;

            // 'real' all posts count
            postsCount = [[NSNumber alloc] initWithInteger:totalPostsCount];
            
            NSDictionary *files = [[opPost objectForKey:@"files"] objectAtIndex:0];

            NSString *tmpThumbnail = [files objectForKey:@"thumbnail"];

            if (!tmpThumbnail) {
                NSLog(@"Something is not right with the thumbnail or full picture");
                continue;
            }
            NSString *thumbPath = [NSString stringWithFormat:@"%@%@/%@", DVACH_BASE_URL, _boardCode, tmpThumbnail];

            // time since first post
            NSInteger timestamp = [[opPost objectForKey:@"timestamp"] integerValue];
            NSString *dateAgo = [DateFormatter dateFromTimestamp:timestamp];

            /**
             Create thred object for storing all info for later use, and write object to mutable array
             */
            DVBThread *threadObj = [[DVBThread alloc] initWithNum:num
                                                          Subject:subject
                                                        opComment:comment
                                                       filesCount:filesCount
                                                       postsCount:postsCount
                                                        thumbPath:thumbPath
                                            andTimeSinceFirstPost:dateAgo];
            [_privateThreadsArray addObject:threadObj];
            threadObj = nil;
        }
        
        NSArray *resultArr = [[NSArray alloc] initWithArray:_privateThreadsArray];
        
        _threadsArray = resultArr;
        
        _currentPage++;
        
        if (_currentPage == _maxPage) {
            _currentPage = 0;
        }
        
        completion(resultArr);
        
    }];
}

- (void)reloadBoardWithCompletion:(void (^)(NSArray *))completion {
    _privateThreadsArray = [NSMutableArray array];
    _currentPage = 0;
    [self loadNextPageWithCompletion:^(NSArray *threadsCompletion) {
        completion(threadsCompletion);
    }];
}



@end
