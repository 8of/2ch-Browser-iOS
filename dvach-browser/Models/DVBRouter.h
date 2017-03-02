//
//  DVBRouter.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 16/11/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class DVBThread;
@class DVBPostViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface DVBRouter : NSObject

+ (void)pushBoardFrom:(UIViewController *)viewController boardCode:(NSString *)boardCode pages:(NSInteger)pages;
/// Full thread
+ (void)pushThreadFrom:(UIViewController *)viewController board:(NSString *)board thread:(NSString *)thread subject:(nullable NSString *)subject comment:(nullable NSString *)comment;
/// Answers only
+ (void)pushAnswersFrom:(UIViewController *)viewController postNum:(NSString *)postNum answers:(NSArray <DVBPostViewModel *> *)answers allPosts:(NSArray <DVBPostViewModel *> *)allPosts;
+ (void)openCreateThreadFrom:(UIViewController *)vc boardCode:(NSString *)boardCode;
+ (void)showComposeFrom:(UIViewController *)vc boardCode:(NSString *)boardCode threadNum:(NSString *)threadNum;
+ (void)openWebmFrom:(UIViewController *)vc url:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
