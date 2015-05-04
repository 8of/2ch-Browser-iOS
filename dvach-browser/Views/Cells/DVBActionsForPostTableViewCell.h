//
//  DVBActionsForPostTableViewCell.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 03/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DVBThreadViewController.h"

@interface DVBActionsForPostTableViewCell : UITableViewCell

- (void)prepareCellWithPostRepliesCount:(NSUInteger)postRepliesCount andIndex:(NSUInteger)index andDisableActionButton:(BOOL)disableActionButton;

@end
