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

- (void)getServiceStatusLater:(void (^)(NSUInteger))completion;
- (void)getBoardsFromNetworkWithCompletion:(void (^)(NSDictionary *))completion;

/**
 *  Get threads for single page of single board
 */
- (void)getThreadsWithBoard:(NSString *)board
                    andPage:(NSUInteger)page
              andCompletion:(void (^)(NSDictionary *))completion;

/**
 *  Get posts for single page of single board
 */
- (void)getPostsWithBoard:(NSString *)board
                andThread:(NSString *)threadNum
            andCompletion:(void (^)(NSDictionary *))completion;

/**
 *  Get usercode cookie in exchange to user's passcode
 */
- (void)getUserCodeWithPasscode:(NSString *)passcode
                  andCompletion:(void (^)(NSString *))completion;
/**
 *  Request key from 2ch server to get captcha image
 */
- (void)requestCaptchaKeyWithCompletion:(void (^)(NSString *))completion;
/**
 *  Post user message to server and return server answer
 *
 *  @param task         <#task description#>
 *  @param board        <#board description#>
 *  @param threadNum    <#threadNum description#>
 *  @param name         <#name description#>
 *  @param email        <#email description#>
 *  @param subject      <#subject description#>
 *  @param comment      <#comment description#>
 *  @param captchaKey   <#captchaKey description#>
 *  @param captchaValue <#captchaValue description#>
 *  @param usercode     <#usercode description#>
 *  @param imageToLoad  <#imageToLoad description#>
 *  @param completion   <#completion description#>
 */
- (void)postMessageWithTask:(NSString *)task
                   andBoard:(NSString *)board
               andThreadnum:(NSString *)threadNum
                    andName:(NSString *)name
                   andEmail:(NSString *)email
                 andSubject:(NSString *)subject
                 andComment:(NSString *)comment
            andcaptchaValue:(NSString *)captchaValue
                andUsercode:(NSString *)usercode
             andImageToLoad:(UIImage *)imageToLoad
              andCompletion:(void (^)(DVBMessagePostServerAnswer *))completion;

@end