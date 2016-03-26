//
//  DVBNetworking.h
//  dvach-browser
//
//  Created by Andy on 10/02/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DVBMessagePostServerAnswer.h"

@interface DVBNetworking : NSObject

- (void)getBoardsFromNetworkWithCompletion:(void (^)(NSDictionary *))completion;

/// Get threads for single page of single board
- (void)getThreadsWithBoard:(NSString *)board andPage:(NSUInteger)page andCompletion:(void (^)(NSDictionary *, NSError *))completionBlock;

/// Get posts for single thread
- (void)getPostsWithBoard:(NSString *)board andThread:(NSString *)threadNum andPostNum:(NSString *)postNum andCompletion:(void (^)(id))completion;

/// Get usercode cookie in exchange to user's passcode
- (void)getUserCodeWithPasscode:(NSString *)passcode
                  andCompletion:(void (^)(NSString *))completion;

/// Post user message to server and return server answer
- (void)postMessageWithTask:(NSString *)task andBoard:(NSString *)board andThreadnum:(NSString *)threadNum andName:(NSString *)name andEmail:(NSString *)email andSubject:(NSString *)subject andComment:(NSString *)comment andcaptchaValue:(NSString *)captchaValue andUsercode:(NSString *)usercode andImagesToUpload:(NSArray *)imagesToUpload andWithoutCaptcha:(BOOL)withoutCaptcha andCaptchId:(NSString *)captchaId andCaptchaCode:(NSString *)captchaCode andCompletion:(void (^)(DVBMessagePostServerAnswer *))completion;

/// Report thread
- (void)reportThreadWithBoardCode:(NSString *)board andThread:(NSString *)thread andComment:(NSString *)comment;

/// After posting we trying to get our new post and parse it from the scratch
- (void)getPostWithBoardCode:(NSString *)board andThread:(NSString *)thread andPostNum:(NSString *)postNum andCompletion:(void (^)(NSArray *))completion;

/// Checking my server for review status
- (void)getReviewStatus:(void (^)(BOOL))completion;

/// Check if we can post without captcha
- (void)canPostWithoutCaptcha:(void (^)(BOOL))completion;

- (void)getCaptchaImageUrl:(BOOL)thread andCompletion:(void (^)(NSString *))completion;

- (NSString *)userAgent;

@end