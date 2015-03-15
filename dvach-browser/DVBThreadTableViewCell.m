//
//  DVBThreadTableViewCell.m
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import "DVBThreadTableViewCell.h"

@interface DVBThreadTableViewCell ()

/**
 *  text of post
 */
@property (nonatomic) IBOutlet UILabel* detailedLabel;
/**
 *  tech label for posts and images count
 */
@property (nonatomic) IBOutlet UILabel* utilityLabel;
/**
 *  image for showing OP thumbnail image
 */
@property (nonatomic) IBOutlet UIImageView *threadThumb;

@end

@implementation DVBThreadTableViewCell

- (void)prepareCellWithThreadObject: (DVBThread *)threadObject {
    /**
     *  Set OP post comment for each thread.
     */
    _detailedLabel.text = threadObject.comment;
    _detailedLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    /**
     Utility text (posts count and files count)
     
     :returns: full ready NSString utility string.
     */
    NSString *postsSubString = NSLocalizedString(@" постов ", @"Часть подстроки ПОСТОВ для статусного сообщения под вступительным текстом каждого сообщения в списке тредов.");
    NSString *imagesSubString = NSLocalizedString(@" изображений ", @"Часть подстроки ИЗОБРАЖЕНИЙ для статусного сообщения под вступительным текстом каждого сообщения в списке тредов.");
    NSString *utilityText = [[NSString alloc] initWithFormat:@"%@%@%@%@", [threadObject.postsCount stringValue], postsSubString, [threadObject.filesCount stringValue], imagesSubString];
    _utilityLabel.text = utilityText;
    _utilityLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    /**
     *  Set thumbnail for OP post of each thread.
     */
    _threadThumb.contentMode = UIViewContentModeScaleAspectFill;
    _threadThumb.clipsToBounds = YES;
    [_threadThumb sd_setImageWithURL:[NSURL URLWithString:threadObject.thumbnail] placeholderImage:[UIImage imageNamed:@"Noimage.png"]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.contentView layoutIfNeeded];
    
    [_detailedLabel sizeToFit];
    _detailedLabel.preferredMaxLayoutWidth = CGRectGetWidth(_detailedLabel.frame);
    
    [_utilityLabel sizeToFit];
    _utilityLabel.preferredMaxLayoutWidth = CGRectGetWidth(_utilityLabel.frame);
}

- (void)prepareForReuse {
    
    _detailedLabel.text = @"";
    _utilityLabel.text = @"";
    
    [self setNeedsUpdateConstraints];
    [self.layer removeAllAnimations];
}

@end