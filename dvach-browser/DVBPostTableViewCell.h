//
//  DVBPostTableViewCell.h
//  dvach-browser
//
//  Created by Andy on 13/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
/**
 *  cell for showing posts in thread Table View Controller
 */
@interface DVBPostTableViewCell : UITableViewCell

@property BOOL isPostHaveImage;
/**
 *  textView for post comment
 */
@property (nonatomic) IBOutlet UITextView *commentTextView;
/**
 *  post thumbnail
 */
@property (nonatomic) IBOutlet UIImageView *postThumb;

- (void)rebuildPostThumbImageWithImagePresence:(BOOL)isImagePresent;

@end