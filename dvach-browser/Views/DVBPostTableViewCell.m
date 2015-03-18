//
//  DVBPostTableViewCell.m
//  dvach-browser
//
//  Created by Andy on 13/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBPostTableViewCell.h"
#import "DVBConstants.h"

static CGFloat const TEXTVIEW_INSET = 8;

@interface DVBPostTableViewCell () <UITextViewDelegate>

@property BOOL isPostHaveImage;

// textView for post comment
@property (nonatomic) IBOutlet UITextView *commentTextView;
// post thumbnail
@property (nonatomic) IBOutlet UIImageView *postThumb;

// Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;

@end

@implementation DVBPostTableViewCell

- (void)awakeFromNib
{
    _commentTextView.delegate = self;
}

- (void)prepareCellWithCommentText:(NSString *)commentText
             andPostThumbUrlString:(NSString *)postThumbUrlString
{
    /**
     *  This is the first part of the fix for fixing broke links in comments.
     */
    _commentTextView.text = nil;
    _commentTextView.text = commentText;
    _commentTextView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    // make insets
    [_commentTextView setTextContainerInset:UIEdgeInsetsMake(TEXTVIEW_INSET, TEXTVIEW_INSET, TEXTVIEW_INSET, TEXTVIEW_INSET)];
    
    // for more tidy images and keep aspect ratio
    _postThumb.contentMode = UIViewContentModeScaleAspectFill;
    _postThumb.clipsToBounds = YES;
    
    // load the image and setting image source depending on presented image or set blank image
    // need to rewrite it to use different table cells if there is no image in post
    if (![postThumbUrlString isEqualToString:@""])
    {
        [_postThumb sd_setImageWithURL:[NSURL URLWithString:postThumbUrlString]
                              placeholderImage:[UIImage imageNamed:@"Noimage.png"]];
        [self rebuildPostThumbImageWithImagePresence:YES];
    }
    else
    {
        _postThumb.image = [UIImage imageNamed:@"Noimage.png"];
        [self rebuildPostThumbImageWithImagePresence:NO];
    }
}

- (void)rebuildPostThumbImageWithImagePresence:(BOOL)isImagePresent
{
    if (isImagePresent)
    {
        _imageLeftConstraint.constant = 8.0f;
        _imageWidthConstraint.constant = 65.0f;
        _isPostHaveImage = YES;
    }
    else
    {
        _imageLeftConstraint.constant = 0;
        _imageWidthConstraint.constant = 0;
        _isPostHaveImage = NO;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.contentView layoutIfNeeded];
}

#pragma  mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView
shouldInteractWithURL:(NSURL *)URL
         inRange:(NSRange)characterRange
{
    BOOL isExternalLinksShoulBeOpenedInChrome = [[NSUserDefaults standardUserDefaults] boolForKey:OPEN_EXTERNAL_LINKS_IN_CHROME];

    if (isExternalLinksShoulBeOpenedInChrome)
    { // && canOpenInChrome) {
        NSString *chromeUrlString = [URL absoluteString];
        chromeUrlString = [chromeUrlString stringByReplacingOccurrencesOfString:HTTPS_SCHEME
                                                                     withString:GOOGLE_CHROME_HTTPS_SCHEME];
        chromeUrlString = [chromeUrlString stringByReplacingOccurrencesOfString:HTTP_SCHEME
                                                                     withString:GOOGLE_CHROME_HTTP_SCHEME];
        NSURL *chromeUrl = [NSURL URLWithString:chromeUrlString];
        BOOL canOpenInChrome = [[UIApplication sharedApplication] canOpenURL:chromeUrl];
        
        if (canOpenInChrome)
        {
            [[UIApplication sharedApplication] openURL:chromeUrl];
            return NO;
        }
        
        return YES;
    }
    
    return YES;
}

@end
