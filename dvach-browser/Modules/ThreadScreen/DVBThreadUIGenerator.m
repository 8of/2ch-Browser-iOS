//
//  DVBThreadUIGenerator.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 19/02/2017.
//  Copyright © 2017 8of. All rights reserved.
//

#import <TUSafariActivity/TUSafariActivity.h>

#import "DVBCommon.h"
#import "DVBThreadUIGenerator.h"
#import "DVBPostStyler.h"
#import "ARChromeActivity.h"

@implementation DVBThreadUIGenerator

+ (void)styleTableNode:(ASTableNode *)tableNode
{
    [UIApplication sharedApplication].keyWindow.backgroundColor = [DVBPostStyler postCellBackgroundColor];
    
    tableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableNode.view.contentInset = UIEdgeInsetsMake([DVBPostStyler elementInset]/2, 0, [DVBPostStyler elementInset]/2, 0);
    tableNode.allowsSelection = NO;
    tableNode.backgroundColor = [DVBPostStyler postCellBackgroundColor];
    tableNode.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableNode.view.showsVerticalScrollIndicator = NO;
    tableNode.view.showsHorizontalScrollIndicator = NO;
}

+ (UIRefreshControl *)refreshControlFor:(ASTableView *)tableView target:(id)target action:(SEL)action
{
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [tableView addSubview:refresh];
    [tableView sendSubviewToBack:refresh];
    [refresh addTarget:target
                action:action
      forControlEvents:UIControlEventValueChanged];
    return refresh;
}

#pragma mark - Buttons & actions

+ (void)shareUrl:(NSString *)urlString fromVC:(UIViewController *)vc fromButton:(UIBarButtonItem *)button
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSArray *objectsToShare = @[url];
    TUSafariActivity *safariActivity = [[TUSafariActivity alloc] init];
    ARChromeActivity *chromeActivity = [[ARChromeActivity alloc] init];
    NSString *openInChromActivityTitle = NSLS(@"ACTIVITY_OPEN_IN_CHROME");
    [chromeActivity setActivityTitle:openInChromActivityTitle];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:@[safariActivity, chromeActivity]];
    
    // Only for iPad
    if ( [activityViewController respondsToSelector:@selector(popoverPresentationController)] ) {
        if (vc.navigationController.isToolbarHidden) {
            activityViewController.popoverPresentationController.sourceView = vc.navigationController.navigationBar;
            activityViewController.popoverPresentationController.sourceRect = vc.navigationController.navigationBar.frame;
        } else {
            activityViewController.popoverPresentationController.barButtonItem = button;
        }
    }
    [vc presentViewController:activityViewController animated:YES completion:nil];
}

+ (void)flagFromVC:(UIViewController *)vc handler:(void (^)(UIAlertAction *))handler
{
    UIAlertController *controller = [[UIAlertController alloc] init];
    UIAlertAction *flag = [UIAlertAction actionWithTitle:NSLS(@"BUTTON_REPORT")
                                                   style:UIAlertActionStyleDestructive
                                                 handler:handler
                             ];
    [controller addAction:flag];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLS(@"BUTTON_CANCEL")
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * _Nonnull action) {}
                             ];
    [controller addAction:cancel];
    [vc presentViewController:controller
                     animated:YES
                   completion:nil];
}

+ (UIBarButtonItem *)composeItemTarget:(id)target action:(SEL)action
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Compose"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:target
                                                            action:action];
    return item;
}

+ (NSArray <UIBarButtonItem *> *)toolbarItemsTarget:(id)target scrollBottom:(SEL)scrollBottom bookmark:(SEL)bookmark share:(SEL)share flag:(SEL)flag reload:(SEL)reload
{
    UIBarButtonItem *scrollItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Bottompage"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:target
                                                            action:scrollBottom];
    UIBarButtonItem *bookmarkItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                                                                target:target
                                                                                action:bookmark];
    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                               target:target
                                                                               action:share];
    UIBarButtonItem *flagItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ReportFlag"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:target
                                                                action:flag];
    UIBarButtonItem *reloadItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                target:target
                                                                                action:reload];
    NSArray <UIBarButtonItem *> *items = @
    [
     scrollItem,
     [self flexItemWithTarget:target],
     bookmarkItem,
     [self flexItemWithTarget:target],
     shareItem,
     [self flexItemWithTarget:target],
     flagItem,
     [self flexItemWithTarget:target],
     reloadItem
    ];
    return items;
}

/// Empty space between toolbar items
+ (UIBarButtonItem *)flexItemWithTarget:(id)target
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:target action:nil];
    return item;
}

+ (NSString *)titleWithSubject:(NSString *)subject andThreadNum:(NSString *)num
{
    /// If thread Subject is empty - return OP post number
    BOOL isSubjectEmpty = [subject isEqualToString:@""];
    if (isSubjectEmpty) {
        return num;
    }

    return subject;
}

@end
