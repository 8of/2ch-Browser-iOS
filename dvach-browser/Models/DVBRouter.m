//
//  DVBRouter.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 16/11/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBRouter.h"

#import "DVBAsyncBoardViewController.h"
#import "DVBThreadViewController.h"
#import "DVBCreatePostViewController.h"

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
    NSString *threadNum = thread.num;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:STORYBOARD_NAME_MAIN
                                                         bundle:nil];
    DVBThreadViewController *threadViewController = (DVBThreadViewController *)[storyboard instantiateViewControllerWithIdentifier:STORYBOARD_ID_THREAD_VIEW_CONTROLLER];
    threadViewController.boardCode = boardCode;
    threadViewController.threadNum = threadNum;
    threadViewController.threadSubject = [DVBThread threadControllerTitleFromTitle:thread.subject andNum:thread.num andComment:thread.comment];
    [viewController.navigationController pushViewController:threadViewController animated:YES];
}

+ (void)pushThreadFrom:(UIViewController *)viewController withThreadNum:(NSString *)threadNum boardCode:(NSString *)boardCode
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:STORYBOARD_NAME_MAIN
                                                         bundle:nil];
    DVBThreadViewController *threadViewController = (DVBThreadViewController *)[storyboard instantiateViewControllerWithIdentifier:STORYBOARD_ID_THREAD_VIEW_CONTROLLER];
    threadViewController.boardCode = boardCode;
    threadViewController.threadNum = threadNum;
    [viewController.navigationController pushViewController:threadViewController animated:YES];
}

+ (void)openCreateThreadFrom:(UIViewController *)viewController boardCode:(NSString *)boardCode
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:STORYBOARD_NAME_MAIN
                                                         bundle:nil];
    DVBCreatePostViewController *createPostViewController = (DVBCreatePostViewController *)[storyboard instantiateViewControllerWithIdentifier:STORYBOARD_ID_CREATE_POST_VIEW_CONTROLLER];
    createPostViewController.createPostViewControllerDelegate = (id<DVBCreatePostViewControllerDelegate>)viewController;
    createPostViewController.threadNum = @"0";
    createPostViewController.boardCode = boardCode;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        // Fix ugly white popover arrow on Popover Controller when dark theme enabled
        createPostViewController.popoverPresentationController.backgroundColor = [UIColor blackColor];
    }
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:createPostViewController];
    [viewController presentViewController:navigationController animated:YES completion:nil];
}

@end
