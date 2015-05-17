//
//  DVBThreadTableViewCell.m
//  dvach-browser
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <UIImageView+AFNetworking.h>

#import "DVBConstants.h"

#import "DVBThreadTableViewCell.h"

@interface DVBThreadTableViewCell ()

@property (nonatomic) IBOutlet UILabel* titleLabel;
@property (nonatomic) IBOutlet UILabel* commentLabel;
@property (nonatomic, weak) IBOutlet UILabel *postsCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UIView *postsCountContainerView;
// Image for showing OP thumbnail image
@property (nonatomic) IBOutlet UIImageView *threadThumb;

@end

@implementation DVBThreadTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self.contentView setOpaque:YES];
    [self.backgroundView setOpaque:YES];

    [_threadThumb setOpaque:YES];
    [_threadThumb.layer setOpaque:YES];
    _threadThumb.contentMode = UIViewContentModeScaleAspectFill;
    _threadThumb.clipsToBounds = YES;

    // _threadThumb.layer.cornerRadius = 14.0f;
    // [_threadThumb.layer setBorderColor: THUMBNAIL_GREY_BORDER];
    // [_threadThumb.layer setBorderWidth: 1.0];

    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.layer.masksToBounds = NO;

    _dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _dateLabel.layer.masksToBounds = NO;

    _commentLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _commentLabel.layer.masksToBounds = NO;

    [_postsCountLabel setOpaque:YES];
    [_postsCountLabel.layer setOpaque:YES];
    _postsCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _postsCountLabel.layer.masksToBounds = NO;

    _postsCountContainerView.layer.cornerRadius = 6.0f;
    [_postsCountContainerView.layer setBorderColor: THUMBNAIL_GREY_BORDER];
    [_postsCountContainerView.layer setBorderWidth: 1.0];
    _postsCountContainerView.layer.masksToBounds = NO;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_LITTLE_BODY_FONT]) {
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];

        _commentLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        _postsCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    }

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _commentLabel.numberOfLines = 3;
    }
}

- (void)prepareCellWithThreadObject: (DVBThread *)threadObject
{
    NSString *title = threadObject.subject;
    if ([title isEqualToString:@""]) {
        title = threadObject.num;
    }

    _titleLabel.text = title;

    _commentLabel.text = threadObject.comment;

    NSURL *thumbUrl = [NSURL URLWithString:threadObject.thumbnail];
    [_threadThumb setImageWithURL:thumbUrl];

    _postsCountLabel.text = [threadObject.postsCount stringValue];

    _dateLabel.text = threadObject.timeSinceFirstPost;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    _titleLabel.text = nil;
    _commentLabel.text = nil;
    _dateLabel.text = nil;
    _postsCountLabel.text = nil;

    [_threadThumb setImage:[UIImage imageNamed:@"Noimage.png"]];
}

@end