//
//  DVBContainerForPostElements.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 26/04/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import "DVBContainerForPostElements.h"

@interface DVBContainerForPostElements () <UITextViewDelegate>

// UI elements
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UIImageView *captchaImage;
@property (nonatomic, weak) IBOutlet UIButton *captchaUpdateButton;
@property (nonatomic, weak) IBOutlet UIButton *uploadButton;

// Constraints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *captchaFieldContainerHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *fromThemeToCaptchaFieldContainer;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contstraintFromPhotoToBottomEdge;

// Constraints original value storages
@property (nonatomic, assign) CGFloat contstraintFromCommentTextToBottomEdgeOriginalValue;

@end

@implementation DVBContainerForPostElements

- (void)awakeFromNib
{
    [self setupAppearance];
}

- (void)setupAppearance
{
    // Captcha image will be in front of activity indicator after appearing.
    _captchaImage.layer.zPosition = 2;

    // Setup commentTextView appearance to look like textField.
    _commentTextView.delegate = self;

    if ([_commentTextView.text isEqualToString:@""]) {
        _commentTextView.text = @"Сообщение";
        _commentTextView.textColor = [UIColor lightGrayColor];
    }

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

    [self registerForKeyboardNotifications];

    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(hideKeyBoard)];

    [self addGestureRecognizer:tapGesture];

    // Get default value for bottom constraint.
    _contstraintFromCommentTextToBottomEdgeOriginalValue = _contstraintFromPhotoToBottomEdge.constant;
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

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@"Сообщение"]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = @"Сообщение";
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

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification *)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGRect keyPadFrame=[[UIApplication sharedApplication].keyWindow convertRect:[[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue] fromView:self];
    CGSize kbSize =keyPadFrame.size;

    CGFloat keyboardHeight = kbSize.height;

    _contstraintFromPhotoToBottomEdge.constant = _contstraintFromCommentTextToBottomEdgeOriginalValue + keyboardHeight;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification *)aNotification
{
    [self layoutIfNeeded];

    _contstraintFromPhotoToBottomEdge.constant = _contstraintFromCommentTextToBottomEdgeOriginalValue;
    [UIView animateWithDuration:1
                     animations:^
    {
         // Called on parent view
         [self.superview layoutIfNeeded];
     }];
}

- (void)hideKeyBoard
{
    [self endEditing:YES];
}

#pragma mark - Upload/Delete button Animation

- (void)changeUploadButtonToDelete
{
    [self layoutIfNeeded];
    [UIView animateWithDuration:0.5f
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.autoresizesSubviews = NO;
                         [_uploadButton setTransform:CGAffineTransformRotate(_uploadButton.transform, M_PI/4)];
                         _uploadButton.tintColor = [UIColor redColor];
                     } completion:nil];
}

- (void)changeUploadButtonToUpload
{
    [self layoutIfNeeded];
    [UIView animateWithDuration:0.5f
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.autoresizesSubviews = NO;
                         [_uploadButton setTransform:CGAffineTransformRotate(_uploadButton.transform, -M_PI/4)];
                         _uploadButton.tintColor = [[[[UIApplication sharedApplication] delegate] window] tintColor];
                     } completion:nil];
}

@end
