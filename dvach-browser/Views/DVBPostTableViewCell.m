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
// show answer to post button
@property (weak, nonatomic) IBOutlet UIButton *answerButton;
// show action sheet for the post
@property (weak, nonatomic) IBOutlet UIButton *actionButton;

// Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;

@end

@implementation DVBPostTableViewCell

- (void)awakeFromNib
{
    _commentTextView.delegate = self;
}

- (void)prepareCellWithCommentText:(NSAttributedString *)commentText andPostThumbUrlString:(NSString *)postThumbUrlString andPostRepliesCount:(NSUInteger)postRepliesCount andIndex:(NSUInteger)index
{
    // prepare Answer button
    _answerButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    NSString *answerButtonPretext = NSLocalizedString(@"Ответы", "Надпись на кнопке к посту для показа количества ответов и перехода к ним");
    NSString *answerButtonPretextNoAnswers = NSLocalizedString(@"Нет ответов", "Надпись на кнопке к посту для показа количества ответов и перехода к ним когда ответов нет");
    NSString *actionButtonPretext = NSLocalizedString(@"Действия", "Надпись на кнопке Действия если действия доступны");
    NSString *actionButtonPretextNoAnswers = NSLocalizedString(@"", "Надпись на кнопке Действия если действия не доступны");
    
    NSString *answerButtonTitle;
    NSString *actionButtonTitle;
    
    if (postRepliesCount > 0) {
        answerButtonTitle = [NSString stringWithFormat:@"%@ (%ld)", answerButtonPretext, (unsigned long)postRepliesCount];
    }
    else {
        answerButtonTitle = answerButtonPretextNoAnswers;
        [_answerButton setEnabled:NO];
    }
    
    if (_disableActionButton) {
        actionButtonTitle = actionButtonPretextNoAnswers;
        [_actionButton setEnabled:NO];
    }
    else {
        actionButtonTitle = actionButtonPretext;
    }
    
    [_answerButton setTitle:answerButtonTitle forState:UIControlStateNormal];
    [_answerButton sizeToFit];
    _answerButton.tag = index;
    
    // prepare action button
    _actionButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [_actionButton setTitle:actionButtonTitle forState:UIControlStateNormal];
    [_actionButton sizeToFit];
    _actionButton.tag = index;
    
    // for more tidy images and keep aspect ratio
    _postThumb.contentMode = UIViewContentModeScaleAspectFill;
    _postThumb.clipsToBounds = YES;
    
    // make insets here, because if we make in reuse... it will fire only when cell will be reused, but will not fire the first times
    [_commentTextView setTextContainerInset:UIEdgeInsetsMake(TEXTVIEW_INSET, TEXTVIEW_INSET, TEXTVIEW_INSET, TEXTVIEW_INSET)];
    _commentTextView.attributedText = commentText;

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
    if (!isImagePresent)
    {
        _imageLeftConstraint.constant = 0;
        _imageWidthConstraint.constant = 0;
        _imageHeightConstraint.constant = 0;
        _isPostHaveImage = NO;
        // [self removeConstraint:_actionsButtonTopConstraint];
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
    
    [_answerButton sizeToFit];
    _answerButton.titleLabel.preferredMaxLayoutWidth = CGRectGetWidth(_answerButton.titleLabel.frame);
    
    [_actionButton sizeToFit];
    _actionButton.titleLabel.preferredMaxLayoutWidth = CGRectGetWidth(_actionButton.titleLabel.frame);
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
    _isPostHaveImage = YES;
    
    [_answerButton setEnabled:YES];
    
    [_actionButton setEnabled:YES];
    
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

@end
