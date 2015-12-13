//
//  DVBThreadTableViewCell.h
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

/**
 *  cell for showing threads in boards Table View Controller
 */

#import <UIKit/UIKit.h>
#import "DVBThread.h"

@interface DVBThreadTableViewCell : UITableViewCell

/// Check if string fits
+ (BOOL)goodFitWithViewWidth:(CGFloat)viewWidth andString:(NSString *)string;

- (void)prepareCellWithTitle:(NSString *)title andComment:(NSString *)comment andThumbnailUrlString:(NSString *)thumbnailUrlString andPostsCount:(NSString *)postsCount andTimeSinceFirstPost:(NSString *)timeSinceFirstPost;

@end