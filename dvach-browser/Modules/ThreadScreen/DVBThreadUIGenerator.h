//
//  DVBThreadUIGenerator.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 19/02/2017.
//  Copyright © 2017 8of. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVBThreadUIGenerator : NSObject

+ (void)styleTableNode:(ASTableNode *)tableNode;
+ (UIRefreshControl *)refreshControlFor:(ASTableView *)tableView target:(id)target action:(SEL)action;
+ (UIBarButtonItem *)composeItemTarget:(id)target action:(SEL)action;
+ (NSArray <UIBarButtonItem *> *)toolbarItemsTarget:(id)target scrollBottom:(SEL)scrollBottom;

@end

NS_ASSUME_NONNULL_END
