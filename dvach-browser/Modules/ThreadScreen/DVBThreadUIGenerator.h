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
+ (UIRefreshControl *)refreshControlFor:(ASTableView *)tableView;

@end

NS_ASSUME_NONNULL_END
