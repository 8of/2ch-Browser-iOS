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

@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) IBOutlet UILabel *commentLabel;
@property (nonatomic, weak) IBOutlet UILabel *postsCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
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
    [_threadThumb setImage:[UIImage imageNamed:@"Noimage.png"]];

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

    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        self.backgroundColor = CELL_BACKGROUND_COLOR;
        [_titleLabel setTextColor:CELL_TEXT_COLOR];
        [_commentLabel setTextColor:CELL_TEXT_COLOR];
        [_postsCountLabel setTextColor:CELL_TEXT_COLOR];
        _postsCountLabel.backgroundColor = CELL_BACKGROUND_COLOR;
        [_dateLabel setTextColor:CELL_TEXT_COLOR];
        [_postsCountContainerView setBackgroundColor:CELL_BACKGROUND_COLOR];
        [_postsCountContainerView.layer setBorderColor:CELL_TEXT_COLOR.CGColor];
    }
}

- (void)prepareCellWithTitle:(NSString *)title andComment:(NSString *)comment andThumbnailUrlString:(NSString *)thumbnailUrlString andPostsCount:(NSString *)postsCount andTimeSinceFirstPost:(NSString *)timeSinceFirstPost
{
    _titleLabel.text = title;
    _commentLabel.text = comment;

    if (thumbnailUrlString) {
        NSLog(@"kek %@", thumbnailUrlString);
        NSURL *thumbnailUrl = [NSURL URLWithString:thumbnailUrlString];
        [_threadThumb setImageWithURL:thumbnailUrl];
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

    [_threadThumb setImage:[UIImage imageNamed:@"Noimage.png"]];
}

@end