//
//  DVBRouter.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 16/11/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBRouter.h"

#import "DVBThread.h"
#import "DVBPostViewModel.h"
#import "DVBAsyncBoardViewController.h"
#import "DVBThreadViewController.h"
#import "DVBCreatePostViewController.h"
#import "DVBAsyncThreadViewController.h"

@implementation DVBRouter

+ (void)pushBoardFrom:(UIViewController *)viewController boardCode:(NSString *)boardCode pages:(NSInteger)pages
{
    DVBAsyncBoardViewController *boardViewController = [[DVBAsyncBoardViewController alloc] initBoardCode:boardCode
                                                                                                    pages:pages];
    [viewController.navigationController pushViewController:boardViewController
                                                   animated:YES];
}

+ (void)pushThreadFrom:(UIViewController *)viewController withThread:(DVBThread *)thread boardCode:(NSString *)boardCode
{
    NSString *subject = [DVBThread threadControllerTitleFromTitle:thread.subject
                                                           andNum:thread.num
                                                       andComment:thread.comment];
    DVBAsyncThreadViewController *vc = [[DVBAsyncThreadViewController alloc] initWithBoardCode:boardCode andThreadNumber:thread.num andThreadSubject:subject];
    [viewController.navigationController pushViewController:vc
                                                   animated:YES];
}

+ (void)pushAnswersFrom:(UIViewController *)viewController postNum:(NSString *)postNum answers:(NSArray <DVBPostViewModel *> *)answers allPosts:(NSArray <DVBPostViewModel *> *)allPosts
{
    DVBAsyncThreadViewController *vc = [[DVBAsyncThreadViewController alloc] initWithPostNum:postNum answers:answers allPosts:allPosts];
    [viewController.navigationController pushViewController:vc
                                                   animated:YES];
}

+ (void)openCreateThreadFrom:(UIViewController *)vc boardCode:(NSString *)boardCode
{
    [self showComposeFrom:vc boardCode:boardCode threadNum:@"0"];
}

+ (void)showComposeFrom:(UIViewController *)vc boardCode:(NSString *)boardCode threadNum:(NSString *)threadNum
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:STORYBOARD_NAME_MAIN
                                                         bundle:nil];
    DVBCreatePostViewController *createPostViewController = (DVBCreatePostViewController *)[storyboard instantiateViewControllerWithIdentifier:STORYBOARD_ID_CREATE_POST_VIEW_CONTROLLER];
    createPostViewController.createPostViewControllerDelegate = (id<DVBCreatePostViewControllerDelegate>)vc;
    createPostViewController.threadNum = threadNum;
    createPostViewController.boardCode = boardCode;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        // Fix ugly white popover arrow on Popover Controller when dark theme enabled
        createPostViewController.popoverPresentationController.backgroundColor = [UIColor blackColor];
    }
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:createPostViewController];
    [vc presentViewController:navigationController
                     animated:YES
                   completion:nil];
}

@end
