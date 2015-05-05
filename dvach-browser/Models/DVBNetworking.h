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

@property (nonatomic, readonly) BOOL filterContent;

- (void)getBoardsFromNetworkWithCompletion:(void (^)(NSDictionary *))completion;

/// Get threads for single page of single board
- (void)getThreadsWithBoard:(NSString *)board andPage:(NSUInteger)page andCompletion:(void (^)(NSDictionary *))completion;

/// Get posts for single page of single board
- (void)getPostsWithBoard:(NSString *)board
                andThread:(NSString *)threadNum
            andCompletion:(void (^)(NSDictionary *))completion;

/// Get usercode cookie in exchange to user's passcode
- (void)getUserCodeWithPasscode:(NSString *)passcode
                  andCompletion:(void (^)(NSString *))completion;

/// Request key from 2ch server to get captcha image
- (void)requestCaptchaKeyWithCompletion:(void (^)(NSString *))completion;

/// Post user message to server and return server answer
- (void)postMessageWithTask:(NSString *)task andBoard:(NSString *)board andThreadnum:(NSString *)threadNum andName:(NSString *)name andEmail:(NSString *)email andSubject:(NSString *)subject andComment:(NSString *)comment andcaptchaValue:(NSString *)captchaValue andUsercode:(NSString *)usercode andImagesToUpload:(NSArray *)imagesToUpload andCompletion:(void (^)(DVBMessagePostServerAnswer *))completion;

/// Report thread
- (void)reportThreadWithBoardCode:(NSString *)board andThread:(NSString *)thread andComment:(NSString *)comment;

@end