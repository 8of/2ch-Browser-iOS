//
//  DVBContainerForPostElements.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 26/04/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>

#import "DVBConstants.h"
#import "DVBContainerForPostElements.h"

@interface DVBContainerForPostElements () <UITextViewDelegate>

// UI elements
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UIImageView *captchaImage;
@property (nonatomic, weak) IBOutlet UIButton *captchaUpdateButton;

// Constraints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *captchaFieldContainerHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *fromThemeToCaptchaFieldContainer;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contstraintFromPhotoToBottomEdge;

// Values for  markup
@property (nonatomic, assign) NSUInteger commentViewSelectedStartLocation;
@property (nonatomic, assign) NSUInteger commentViewSelectedLength;
@property (nonatomic, assign) NSUInteger commentViewNeedToSetCarretToPosition;

@end

@implementation DVBContainerForPostElements

- (void)awakeFromNib
{
    [self setupAppearance];

    _commentViewSelectedStartLocation = 0;
    _commentViewSelectedLength = 0;
}

- (void)setupAppearance
{
    // Captcha image will be in front of activity indicator after appearing.
    _captchaImage.layer.zPosition = 2;

    // Captch button will be in front of everything
    _captchaUpdateButton.layer.zPosition = 3;

    // Setup commentTextView appearance to look like textField.
    _commentTextView.delegate = self;

    // Delete textView insets.
    _commentTextView.textContainer.lineFragmentPadding = 0;
    _commentTextView.textContainerInset = UIEdgeInsetsZero;

    // Setup dynamic font sizes.
    _nameTextField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _subjectTextField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _captchaValueTextField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _commentTextView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _captchaUpdateButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

    // Setup button appearance.
    _captchaUpdateButton.adjustsImageWhenDisabled = YES;
    [_captchaUpdateButton sizeToFit];

    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(hideKeyBoard)];

    [self addGestureRecognizer:tapGesture];

    // For iPad we set bottom padding less
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _contstraintFromPhotoToBottomEdge.constant = 15.0f;
    }

    [_commentTextView becomeFirstResponder];
}

- (void)changeConstraintsIfUserCodeNotEmpty
{
    _captchaFieldContainerHeight.constant = 0;
    _fromThemeToCaptchaFieldContainer.constant = 0;

    [_captchaValueTextField removeConstraints:_captchaValueTextField.constraints];
    [_captchaValueTextField removeFromSuperview];

    [_captchaUpdateButton removeConstraints:_captchaUpdateButton.constraints];
    [_captchaUpdateButton removeFromSuperview];

    [_activityIndicator removeFromSuperview];
}

#pragma mark - UITextViewDelegate

- (BOOL)isCommentPlaceholderNow
{
    NSString *placeholder = NSLocalizedString(PLACEHOLDER_COMMENT_FIELD, @"Placeholder для поля комментария при отправке ответа на пост");

    if ([_commentTextView.text isEqualToString:placeholder]) {
        return YES;
    }

    return NO;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([self isCommentPlaceholderNow]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = PLACEHOLDER_COMMENT_FIELD;
        textView.textColor = [UIColor lightGrayColor];
    }
    [textView resignFirstResponder];
}

#pragma mark - Captcha

- (void)clearCaptchaValueField
{
    _captchaValueTextField.text = @"";
}

- (void)clearCaptchaImage
{
    [_captchaImage setImage:nil];
}

- (void)setCaptchaImageWithUrlString:(NSString *)urlString
{
    [_captchaImage sd_setImageWithURL:[NSURL URLWithString:urlString]];
}

#pragma mark - Keyboard

- (void)hideKeyBoard
{
    [self endEditing:YES];
}

#pragma mark - 2ch markup

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    NSRange selectedRange = _commentTextView.selectedRange;
    _commentViewSelectedStartLocation = selectedRange.location;
    _commentViewSelectedLength = selectedRange.length;
}

/**
 *  Wrap comment in commentTextView
 */
- (void)wrapTextWithSender:(id)sender andTagToInsert:(NSString *)tagToInsert
{
    if (![self isCommentPlaceholderNow]) {
        NSUInteger locationForOpenTag = _commentViewSelectedStartLocation;
        NSUInteger locationForCloseTag = locationForOpenTag + _commentViewSelectedLength;

        NSString *tagToinsertBefore = [NSString stringWithFormat:@"[%@]", tagToInsert];
        NSString *tagToinsertAfter = [NSString stringWithFormat:@"[/%@]", tagToInsert];

        NSMutableString *mutableCommentString = [NSMutableString stringWithString:_commentTextView.text];

        // Insiert close tag first because otherwise its position will change and we'll need to recalculate it
        [mutableCommentString insertString:tagToinsertAfter
                                   atIndex:locationForCloseTag];
        [mutableCommentString insertString:tagToinsertBefore
                                   atIndex:locationForOpenTag];

        NSString *newCommentString = mutableCommentString;

        _commentViewNeedToSetCarretToPosition = _commentViewSelectedStartLocation + tagToinsertBefore.length;
        
        _commentTextView.text = newCommentString;

        _commentTextView.selectedRange = NSMakeRange(_commentViewNeedToSetCarretToPosition,0);
    }
}

- (IBAction)insertBoldTagAction:(id)sender
{
    [self wrapTextWithSender:sender andTagToInsert:@"b"];
}

- (IBAction)insertItalicTagAction:(id)sender
{
    [self wrapTextWithSender:sender andTagToInsert:@"i"];
}

- (IBAction)insertSpoilerTagAction:(id)sender
{
    [self wrapTextWithSender:sender andTagToInsert:@"spoiler"];
}

- (IBAction)insertUnderlineTagAction:(id)sender
{
    [self wrapTextWithSender:sender andTagToInsert:@"u"];
}

- (IBAction)insertStrikeTagAction:(id)sender
{
    [self wrapTextWithSender:sender andTagToInsert:@"s"];
}

#pragma mark - Upload/Delete button Animation

- (void)changeUploadButtonToDeleteWithButton:(UIButton *)button
{
    button.layer.cornerRadius = 11.0f;

    [self layoutIfNeeded];
    [UIView animateWithDuration:0.3f
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.autoresizesSubviews = NO;
                         [button setTransform:CGAffineTransformRotate(button.transform, M_PI/4)];
                         button.backgroundColor = [UIColor redColor];
                     } completion:nil];
}

- (void)changeUploadButtonToUploadWithButton:(UIButton *)button
{
    [self layoutIfNeeded];
    [UIView animateWithDuration:0.3f
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.autoresizesSubviews = NO;
                         [button setTransform:CGAffineTransformRotate(button.transform, -M_PI/4)];
                         button.backgroundColor = [UIColor clearColor];
                     } completion:nil];
}

@end
