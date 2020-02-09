//
//  DVBThreadUIGenerator.h
//  dvach-browser
//
//  Created by Andy on 19/02/2017.
//  Copyright © 2017 8of. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVBThreadUIGenerator : NSObject

+ (void)styleTableNode:(ASTableNode *)tableNode;
+ (UIRefreshControl *)refreshControlFor:(ASTableView *)tableView target:(id)target action:(SEL)action;
+ (UIBarButtonItem *)composeItemTarget:(id)target action:(SEL)action;
+ (NSArray <UIBarButtonItem *> *)toolbarItemsTarget:(id)target scrollBottom:(SEL)scrollBottom bookmark:(SEL)bookmark share:(SEL)share flag:(SEL)flag reload:(SEL)reload;
/// Share
+ (void)shareUrl:(NSString *)urlString fromVC:(UIViewController *)vc fromButton:(UIBarButtonItem *)button;
/// Flag
+ (void)flagFromVC:(UIViewController *)vc handler:(void (^)(UIAlertAction *))handler;
+ (NSString *)titleWithSubject:(NSString *)subject andThreadNum:(NSString *)num;
+ (UIView *)errorView;
+ (UIActivityIndicatorView *)footerView;

@end

NS_ASSUME_NONNULL_END
