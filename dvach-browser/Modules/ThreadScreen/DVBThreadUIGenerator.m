//
//  DVBThreadUIGenerator.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 19/02/2017.
//  Copyright © 2017 8of. All rights reserved.
//

#import "DVBThreadUIGenerator.h"
#import "DVBPostStyler.h"

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

#pragma mark - Buttons

+ (UIBarButtonItem *)composeItemTarget:(id)target action:(SEL)action
{
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Compose"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:target
                                                            action:action];
    return item;
}

+ (NSArray <UIBarButtonItem *> *)toolbarItemsTarget:(id)target scrollBottom:(SEL)scrollBottom
{
    UIBarButtonItem *scrollItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Bottompage"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:target
                                                            action:scrollBottom];
    return @[scrollItem];
}

@end
