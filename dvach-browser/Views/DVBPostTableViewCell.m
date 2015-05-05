//
//  DVBPostTableViewCell.m
//  dvach-browser
//
//  Created by Andy on 13/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import "DVBPostTableViewCell.h"
#import "DVBConstants.h"

@interface DVBPostTableViewCell () <UITextViewDelegate>

@property BOOL isPostHaveImage;
// Thumbnail url
@property (nonatomic, strong) NSString *fullPathUrlString;
// TextView for post comment
@property (nonatomic) IBOutlet UITextView *commentTextView;
// Post thumbnail
@property (nonatomic) IBOutlet UIImageView *postThumb;

// Constraints - image
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;

// Constraints - video-icon
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *videoiconWidthContstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *videoiconHeightContstraint;

@end

@implementation DVBPostTableViewCell

- (void)awakeFromNib
{
    _commentTextView.delegate = self;
}

- (void)prepareCellWithCommentText:(NSAttributedString *)commentText andPostThumbUrlString:(NSString *)postThumbUrlString andPostFullUrlString:(NSString *)postFullUrlString  andShowVideoIcon:(BOOL)showVideoIcon
{
    
    // for more tidy images and keep aspect ratio
    _postThumb.contentMode = UIViewContentModeScaleAspectFill;
    _postThumb.clipsToBounds = YES;
    
    // set minimum delay before textView recognize tap on link
    _commentTextView.delaysContentTouches = NO;

    // Delete insets
    _commentTextView.textContainer.lineFragmentPadding = 0;
    _commentTextView.textContainerInset = UIEdgeInsetsZero;

    _commentTextView.attributedText = commentText;

    // load the image and setting image source depending on presented image or set blank image
    if (![postThumbUrlString isEqualToString:@""]) {
        [_postThumb sd_setImageWithURL:[NSURL URLWithString:postThumbUrlString]
                      placeholderImage:[UIImage imageNamed:@"Noimage.png"]
                               options:SDWebImageRetryFailed];

        [self rebuildPostThumbImageWithImagePresence:YES
                            andWithVideoIconPresence:showVideoIcon];

        _fullPathUrlString = postFullUrlString;
    }
    else {
        _postThumb.image = [UIImage imageNamed:@"Noimage.png"];
        [self rebuildPostThumbImageWithImagePresence:NO
                            andWithVideoIconPresence:NO];
    }
}

- (void)rebuildPostThumbImageWithImagePresence:(BOOL)isImagePresent andWithVideoIconPresence:(BOOL)videoIconPresentce
{
    if (!isImagePresent) {
        _imageLeftConstraint.constant = 0;
        _imageWidthConstraint.constant = 0;
        _imageHeightConstraint.constant = 0;
        _isPostHaveImage = NO;
    }

    if (!videoIconPresentce) {
        _videoiconWidthContstraint.constant = 0;
        _videoiconHeightContstraint.constant = 0;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self.contentView layoutIfNeeded];
}

// fix problems with autolayout
-(void)didMoveToSuperview
{
    [self layoutIfNeeded];
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    _commentTextView.text = nil;
    _commentTextView.attributedText = nil;
    
    [_postThumb setImage:nil];
    
    _imageLeftConstraint.constant = 8.0f;
    _imageWidthConstraint.constant = 65.0f;
    _imageHeightConstraint.constant = 65.0f;
    _videoiconWidthContstraint.constant = 30.0f;
    _videoiconHeightContstraint.constant = 30.0f;
    _isPostHaveImage = YES;
    
    [self setNeedsUpdateConstraints];
    [self.layer removeAllAnimations];
}

#pragma  mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    if (_threadViewController) {
        UrlNinja *urlNinja = [UrlNinja unWithUrl:URL];
        BOOL isLocalPostLink = [_threadViewController isLinkInternalWithLink:urlNinja];

        if (isLocalPostLink) {

            return NO;
        }
        // there is no need to return something here - because othervise
        // we couldn't open link in external browser at all
    }
    
    BOOL isExternalLinksShoulBeOpenedInChrome = [[NSUserDefaults standardUserDefaults] boolForKey:OPEN_EXTERNAL_LINKS_IN_CHROME];

    if (isExternalLinksShoulBeOpenedInChrome) {
        NSString *chromeUrlString = [URL absoluteString];
        chromeUrlString = [chromeUrlString stringByReplacingOccurrencesOfString:HTTPS_SCHEME
                                                                     withString:GOOGLE_CHROME_HTTPS_SCHEME];
        chromeUrlString = [chromeUrlString stringByReplacingOccurrencesOfString:HTTP_SCHEME
                                                                     withString:GOOGLE_CHROME_HTTP_SCHEME];
        NSURL *chromeUrl = [NSURL URLWithString:chromeUrlString];
        BOOL canOpenInChrome = [[UIApplication sharedApplication] canOpenURL:chromeUrl];
        
        if (canOpenInChrome) {
            [[UIApplication sharedApplication] openURL:chromeUrl];

            return NO;
        }
        
        return YES;
    }
    
    return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    NSRange selectedRange = _commentTextView.selectedRange;
    NSUInteger selectedLength = selectedRange.length;
    if (selectedLength > 1) {
        _threadViewController.quoteString = [self createQuoteStringWithSelectedRange:selectedRange];
    }
}
/**
 *  Extract selected string from full comment
 *
 *  @param selectedRange range to determine what part of
 *
 *  @return extracted string
 */
- (NSString *)createQuoteStringWithSelectedRange:(NSRange)selectedRange
{
    NSString *commentString = _commentTextView.text;

    return [commentString substringWithRange:selectedRange];
}

#pragma mark - Actions

- (IBAction)touchFirstPicture:(id)sender {
    [_threadViewController openMediaWithUrlString:_fullPathUrlString];
}

@end
