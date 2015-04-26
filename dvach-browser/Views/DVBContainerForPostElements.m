//
//  DVBContainerForPostElements.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 26/04/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import "DVBContainerForPostElements.h"

@interface DVBContainerForPostElements ()

// UI elements
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UIImageView *captchaImage;
@property (nonatomic, weak) IBOutlet UIButton *captchaUpdateButton;
@property (nonatomic, weak) IBOutlet UIButton *uploadButton;

// Constraints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *captchaFieldHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *fromThemeToCaptchaField;

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
    [_commentTextView.layer setBackgroundColor: [[UIColor whiteColor] CGColor]];
    [_commentTextView.layer setBorderColor: [[[UIColor grayColor] colorWithAlphaComponent:0.2] CGColor]];
    [_commentTextView.layer setBorderWidth: 1.0];
    [_commentTextView.layer setCornerRadius:5.0f];
    [_commentTextView.layer setMasksToBounds:YES];
    [_commentTextView setTextContainerInset:UIEdgeInsetsMake(5, 5, 5, 5)];

    // Setup dynamic font sizes.
    _nameTextField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _subjectTextField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _captchaValueTextField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _commentTextView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _captchaUpdateButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

    // Setup button appearance.
    _captchaUpdateButton.adjustsImageWhenDisabled = YES;
    [_captchaUpdateButton sizeToFit];
}

- (void)changeConstraintsIfUserCodeNotEmpty
{
    _captchaFieldHeight.constant = 0;
    _fromThemeToCaptchaField.constant = 0;

    [_captchaValueTextField removeConstraints:_captchaValueTextField.constraints];
    [_captchaValueTextField removeFromSuperview];

    [_captchaUpdateButton removeConstraints:_captchaUpdateButton.constraints];
    [_captchaUpdateButton removeFromSuperview];

    [_activityIndicator removeFromSuperview];
}

- (void)clearCaptchaValueField
{
    _captchaValueTextField.text = @"";
}

#pragma mark - Captcha

- (void)clearCaptchaImage
{
    [_captchaImage setImage:nil];
}

- (void)setCaptchaImageWithUrlString:(NSString *)urlString
{
    [_captchaImage sd_setImageWithURL:[NSURL URLWithString:urlString]];
}

#pragma mark - Upload/Delete button Animation

- (void)changeUploadButtonToDelete
{
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
