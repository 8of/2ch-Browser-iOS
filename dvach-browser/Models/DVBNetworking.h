//
//  DVBNetworking.h
//  dvach-browser
//
//  Created by Andy on 10/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVBCommon.h"
#import "DVBConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVBNetworking : NSObject

- (void)getBoardsFromNetworkWithCompletion:(void (^)( NSDictionary * _Nullable))completion;

/// Get threads for single page of single board
- (void)getThreadsWithBoard:(NSString *)board andPage:(NSUInteger)page andCompletion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completionBlock;

/// Get posts for single thread
- (void)getPostsWithBoard:(NSString *)board andThread:(NSString *)threadNum andPostNum:(NSString *)postNum andCompletion:(void (^)(id _Nullable))completion;

/// Report thread
- (void)reportThreadWithBoardCode:(NSString *)board andThread:(NSString *)thread andComment:(NSString *)comment;

/// After posting we trying to get our new post and parse it from the scratch
- (void)getPostWithBoardCode:(NSString *)board andThread:(NSString *)thread andPostNum:(NSString *)postNum andCompletion:(void (^)(NSArray * _Nullable))completion;

- (NSString * _Nullable)userAgent;

@end

NS_ASSUME_NONNULL_END
