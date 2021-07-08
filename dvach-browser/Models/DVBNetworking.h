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
#import "DVBMessagePostServerAnswer.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVBNetworking : NSObject

- (void)getBoardsFromNetworkWithCompletion:(void (^)( NSDictionary * _Nullable))completion;

/// Get threads for single page of single board
- (void)getThreadsWithBoard:(NSString *)board andPage:(NSUInteger)page andCompletion:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completionBlock;

/// Get posts for single thread
- (void)getPostsWithBoard:(NSString *)board andThread:(NSString *)threadNum andPostNum:(NSString *)postNum andCompletion:(void (^)(id _Nullable))completion;

/// Get usercode cookie in exchange to user's passcode
- (void)getUserCodeWithPasscode:(NSString *)passcode
                  andCompletion:(void (^)(NSString * _Nullable))completion;

/// Post user message to server and return server answer
- (void)postMessageWithBoard:(NSString *)board andThreadnum:(NSString *)threadNum andName:(NSString *)name andEmail:(NSString *)email andSubject:(NSString *)subject andComment:(NSString *)comment andUsercode:(NSString *)usercode andImagesToUpload:(NSArray *)imagesToUpload andCaptchaParameters:(NSDictionary *)captchaParameters andCompletion:(void (^)(DVBMessagePostServerAnswer *))completion;

/// Report thread
- (void)reportThreadWithBoardCode:(NSString *)board andThread:(NSString *)thread andComment:(NSString *)comment;

/// After posting we trying to get our new post and parse it from the scratch
- (void)getPostWithBoardCode:(NSString *)board andThread:(NSString *)thread andPostNum:(NSString *)postNum andCompletion:(void (^)(NSArray * _Nullable))completion;

/// Check if we can post without captcha
- (void)canPostWithoutCaptcha:(void (^)(BOOL))completion;

- (void)getCaptchaImageUrl:(NSString * _Nullable)threadNum andCompletion:(void (^)(NSString * _Nullable, NSString * _Nullable, NSError * _Nullable))completion;

- (NSString * _Nullable)userAgent;

/// AP captcha
- (void)tryApCaptchaWithCompletion:(void (^)(NSString * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
