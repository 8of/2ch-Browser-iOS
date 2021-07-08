//
//  DVBRouter.m
//  dvach-browser
//
//  Created by Andy on 16/11/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import "DVBConstants.h"
#import "DVBRouter.h"

#import "DVBThread.h"
#import "DVBPostViewModel.h"
#import "DVBDefaultsManager.h"
#import "DVBAsyncBoardViewController.h"
#import "DVBAsyncThreadViewController.h"
#import "DVBWebmViewController.h"

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
    [self showComposeFrom:vc boardCode:boardCode threadNum:nil];
}

+ (void)showComposeFrom:(UIViewController *)vc boardCode:(NSString *)boardCode threadNum:(nullable NSString *)threadNum
{
    NSString *fullURL = threadNum
      ? [NSString stringWithFormat:@"%@%@/%@/res/%@.html", HTTPS_SCHEME, DVACH_DOMAIN, boardCode, threadNum]
      : [NSString stringWithFormat:@"%@%@/%@", HTTPS_SCHEME, DVACH_DOMAIN, boardCode];
  SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:[[NSURL alloc] initWithString:fullURL]];
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:safariViewController];
  navigationController.navigationBarHidden = YES;

  if (IS_IPAD) {
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    safariViewController.preferredContentSize = CGSizeMake(320, 480);
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
    DVBWebmViewController *webmViewController = [[DVBWebmViewController alloc] initURL:url];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:webmViewController];

    if (IS_IPAD) {
      if ([DVBDefaultsManager isDarkMode]) {
        // Fix ugly white popover arrow on Popover Controller when dark theme enabled
        navigationController.popoverPresentationController.backgroundColor = [UIColor blackColor];
      }
    }

    [vc presentViewController:navigationController
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
