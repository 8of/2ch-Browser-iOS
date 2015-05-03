//
//  DVBPostTableViewCell.h
//  dvach-browser
//
//  Created by Andy on 13/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

// Cell for showing posts in thread Table View Controller

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "DVBThreadViewController.h"

@interface DVBPostTableViewCell : UITableViewCell

// Pass data to cell
- (void)prepareCellWithCommentText:(NSAttributedString *)commentText andPostThumbUrlString:(NSString *)postThumbUrlString andPostFullUrlString:(NSString *)postFullUrlString andShowVideoIcon:(BOOL)showVideoIcon;

@property (nonatomic, strong) DVBThreadViewController *threadViewController;

@end
