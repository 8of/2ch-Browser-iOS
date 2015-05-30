//
//  DVBPostTableViewCell.h
//  dvach-browser
//
//  Created by Andy on 13/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

// Cell for showing posts in thread Table View Controller

#import <UIKit/UIKit.h>

#import "DVBThreadViewController.h"

@interface DVBPostTableViewCell : UITableViewCell

@property (nonatomic, strong) DVBThreadViewController *threadViewController;

- (void)prepareCellWithTitle:(NSString *)title andCommentText:(NSAttributedString *)commentText andWithPostRepliesCount:(NSUInteger)postRepliesCount andIndex:(NSUInteger)index andDisableActionButton:(BOOL)disableActionButton andThumbPathesArray:(NSArray *)thumbPathesArray andPathesArray:(NSArray *)pathesArray;

@end
