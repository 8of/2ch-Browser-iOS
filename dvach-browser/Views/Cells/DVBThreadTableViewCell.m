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

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *commentLabel;
@property (nonatomic, weak) IBOutlet UILabel *postsCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UIView *postsCountContainerView;
// Image for showing OP thumbnail image
@property (nonatomic, weak) IBOutlet UIImageView *threadThumb;

@end

@implementation DVBThreadTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self.contentView setOpaque:YES];
    [self.backgroundView setOpaque:YES];

    _threadThumb.opaque = YES;
    _threadThumb.contentMode = UIViewContentModeScaleAspectFill;
    _threadThumb.clipsToBounds = YES;
    _threadThumb.image =[UIImage imageNamed:FILENAME_THUMB_IMAGE_PLACEHOLDER];

    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.layer.masksToBounds = NO;
    _titleLabel.opaque = YES;
    _titleLabel.backgroundColor = [UIColor whiteColor];

    _dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _dateLabel.layer.masksToBounds = NO;
    _dateLabel.opaque = YES;
    _dateLabel.backgroundColor = [UIColor whiteColor];

    _commentLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _commentLabel.layer.masksToBounds = NO;
    _commentLabel.opaque = YES;
    _commentLabel.backgroundColor = [UIColor whiteColor];

    _postsCountLabel.opaque = YES;
    _postsCountLabel.layer.opaque = YES;
    _postsCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _postsCountLabel.layer.masksToBounds = NO;

    _postsCountContainerView.layer.cornerRadius = 6.0f;
    _postsCountContainerView.layer.borderColor = THUMBNAIL_GREY_BORDER;
    _postsCountContainerView.layer.borderWidth = 1.0;
    _postsCountContainerView.layer.masksToBounds = NO;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_LITTLE_BODY_FONT]) {
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];

        _commentLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        _postsCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    }

    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        self.backgroundColor = CELL_BACKGROUND_COLOR;
        _titleLabel.textColor = CELL_TEXT_COLOR;
        _titleLabel.backgroundColor = CELL_BACKGROUND_COLOR;
        _commentLabel.textColor = CELL_TEXT_COLOR;
        _commentLabel.backgroundColor = CELL_BACKGROUND_COLOR;
        _postsCountLabel.textColor = CELL_TEXT_COLOR;
        _postsCountLabel.backgroundColor = CELL_BACKGROUND_COLOR;
        _dateLabel.textColor = CELL_TEXT_COLOR;
        _dateLabel.backgroundColor = CELL_BACKGROUND_COLOR;
        _postsCountContainerView.backgroundColor = CELL_BACKGROUND_COLOR;
        _postsCountContainerView.layer.borderColor = CELL_TEXT_COLOR.CGColor;
    }
}

- (void)prepareCellWithTitle:(NSString *)title andComment:(NSString *)comment andThumbnailUrlString:(NSString *)thumbnailUrlString andPostsCount:(NSString *)postsCount andTimeSinceFirstPost:(NSString *)timeSinceFirstPost
{
    _titleLabel.text = title;
    _commentLabel.text = comment;

    if (thumbnailUrlString) {
        NSURL *thumbnailUrl = [NSURL URLWithString:thumbnailUrlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:thumbnailUrl];
        NSString *userAgent = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_USERAGENT_KEY];

        [request setValue:userAgent forHTTPHeaderField:NETWORK_HEADER_USERAGENT_KEY];

        [_threadThumb setImageWithURLRequest:[request copy]
                            placeholderImage:nil
                                     success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nonnull response, UIImage * _Nonnull image)
        {
            _threadThumb.image = image;
        } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nonnull response, NSError * _Nonnull error) { }];
    }

    _postsCountLabel.text = postsCount;
    _dateLabel.text = timeSinceFirstPost;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    _titleLabel.text = nil;
    _commentLabel.text = nil;
    _dateLabel.text = nil;
    _postsCountLabel.text = nil;
    _threadThumb.image = nil;

    [_threadThumb setImage:[UIImage imageNamed:FILENAME_THUMB_IMAGE_PLACEHOLDER]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.contentView layoutIfNeeded];
}

// fix problems with autolayout
- (void)didMoveToSuperview
{
    [self layoutIfNeeded];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

@end
