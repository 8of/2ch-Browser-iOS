//
//  DVBRouter.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 16/11/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBRouter.h"
#import "DVBAlertGenerator.h"

#import "DVBThread.h"
#import "DVBPostViewModel.h"
#import "DVBDefaultsManager.h"
#import "DVBAsyncBoardViewController.h"
#import "DVBAsyncThreadViewController.h"
#import "DVBCreatePostViewController.h"

@implementation DVBRouter

+ (void)pushBoardFrom:(UIViewController *)viewController boardCode:(NSString *)boardCode pages:(NSInteger)pages
{
    DVBAsyncBoardViewController *boardViewController = [[DVBAsyncBoardViewController alloc] initBoardCode:boardCode
                                                                                                    pages:pages];
    [viewController.navigationController pushViewController:boardViewController
                                                   animated:YES];
}

+ (void)pushThreadFrom:(UIViewController *)viewController board:(NSString *)board thread:(NSString *)thread subject:(nullable NSString *)subject comment:(nullable NSString *)comment
{
    NSString *vcSubject = [DVBThread threadControllerTitleFromTitle:subject
                                                           andNum:thread
                                                       andComment:comment];
    DVBAsyncThreadViewController *vc = [[DVBAsyncThreadViewController alloc] initWithBoardCode:board andThreadNumber:thread andThreadSubject:vcSubject];
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
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:createPostViewController];

  if (IS_IPAD) {
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    createPostViewController.preferredContentSize = CGSizeMake(320, 480);
    navigationController.popoverPresentationController.delegate = (id<UIPopoverPresentationControllerDelegate>)vc;
    navigationController.popoverPresentationController.barButtonItem = vc.navigationItem.rightBarButtonItem;
    if ([DVBDefaultsManager isDarkMode]) {
      // Fix ugly white popover arrow on Popover Controller when dark theme enabled
      navigationController.popoverPresentationController.backgroundColor = [UIColor blackColor];
    }
  }

  [vc presentViewController:navigationController
                   animated:YES
                 completion:nil];
}

+ (void)openWebmFrom:(UIViewController *)vc url:(NSURL *)url
{
  [vc presentViewController:[DVBAlertGenerator webmDeprecatedAlert]
                   animated:YES
                 completion:nil];
}

+ (void)openAVPlayerFrom:(UIViewController *)vc url:(NSURL *)url
{
  AVPlayerViewController *avPlayerVC = [AVPlayerViewController new];
  AVPlayer *player = [[AVPlayer alloc] initWithURL:url];
  player.muted = YES;
  avPlayerVC.player = player;
  [vc presentViewController:avPlayerVC animated:YES completion:^{
    [player play];
  }];
}

@end
