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

// Text of post
@property (nonatomic) IBOutlet UILabel* detailedLabel;
// Tech label for posts and images count
@property (nonatomic) IBOutlet UILabel* utilityLabel;
// Image for showing OP thumbnail image
@property (nonatomic) IBOutlet UIImageView *threadThumb;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;

@end

@implementation DVBThreadTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    _threadThumb.contentMode = UIViewContentModeScaleAspectFill;
    _threadThumb.clipsToBounds = YES;

    _detailedLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _utilityLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _detailedLabel.numberOfLines = 3;
    }
}

- (void)prepareCellWithThreadObject: (DVBThread *)threadObject
{
    // Set OP post comment for each thread.
    _detailedLabel.text = threadObject.comment;

    /**
     Utility text (posts count and files count)
     
     :returns: full ready NSString utility string.
     */
    NSString *postsSubString = NSLocalizedString(@" постов ", @"Часть подстроки ПОСТОВ для статусного сообщения под вступительным текстом каждого сообщения в списке тредов.");
    NSString *imagesSubString = NSLocalizedString(@" изображений ", @"Часть подстроки ИЗОБРАЖЕНИЙ для статусного сообщения под вступительным текстом каждого сообщения в списке тредов.");
    NSString *utilityText = [[NSString alloc] initWithFormat:@"%@%@%@%@", [threadObject.postsCount stringValue], postsSubString, [threadObject.filesCount stringValue], imagesSubString];
    _utilityLabel.text = utilityText;

    // Set thumbnail for OP post of each thread.

    NSURL *thumbUrl = [NSURL URLWithString:threadObject.thumbnail];

    UIImage *placeholderImage = [UIImage imageNamed:@"Noimage.png"];
    [_threadThumb sd_setImageWithURL:thumbUrl placeholderImage:placeholderImage];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self.contentView layoutIfNeeded];

    [_detailedLabel sizeToFit];
    _detailedLabel.preferredMaxLayoutWidth = CGRectGetWidth(_detailedLabel.frame);

    [_utilityLabel sizeToFit];
    _utilityLabel.preferredMaxLayoutWidth = CGRectGetWidth(_utilityLabel.frame);
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    _detailedLabel.text = @"";
    _utilityLabel.text = @"";

    [self setNeedsUpdateConstraints];
    [self.layer removeAllAnimations];
}

@end