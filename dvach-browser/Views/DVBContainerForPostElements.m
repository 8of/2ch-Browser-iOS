//
//  DVBContainerForPostElements.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 26/04/15.
//  Copyright (c) 2015 8of. All rights reserved.
//
#import <CoreImage/CoreImage.h>
#import <UIImageView+AFNetworking.h>

#import "DVBCommon.h"
#import "DVBConstants.h"

#import "DVBContainerForPostElements.h"
#import "DVBCreatePostScrollView.h"

static CGFloat const IMAGE_CHANGE_ANIMATE_TIME = 0.3f;

@interface DVBContainerForPostElements () <UITextViewDelegate>

@property (nonatomic, assign) UIEdgeInsets originalInsets;

// UI elements
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UIImageView *captchaImage;
@property (nonatomic, weak) IBOutlet UIButton *captchaUpdateButton;

// Constraints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *captchaFieldContainerHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *fromThemeToCaptchaFieldContainer;

// Values for  markup
@property (nonatomic, assign) NSUInteger commentViewSelectedStartLocation;
@property (nonatomic, assign) NSUInteger commentViewSelectedLength;
@property (nonatomic, assign) NSUInteger commentViewNeedToSetCarretToPosition;

@end

@implementation DVBContainerForPostElements

- (void)awakeFromNib
{
    [self setupAppearance];

    DVBCreatePostScrollView *scrollView = (DVBCreatePostScrollView *)self.superview;
    scrollView.canCancelContentTouches = YES;

    _commentViewSelectedStartLocation = 0;
    _commentViewSelectedLength = 0;
}

- (void)setupAppearance
{
    NSArray *arrayOfTextFields = @
    [
      _subjectTextField,
      _nameTextField,
      _emailTextField,
      _captchaValueTextField
    ];

    NSArray *textFieldPlaceholders = @
    [
      NSLS(@"FIELD_POST_THEME"),
      NSLS(@"FIELD_POST_NAME"),
      NSLS(@"FIELD_POST_EMAIL"),
      NSLS(@"FIELD_POST_CAPTCHA")
    ];

    [arrayOfTextFields enumerateObjectsUsingBlock:^(UITextField *textField, NSUInteger idx, BOOL *stop) {
        textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textFieldPlaceholders[idx]
                                                                          attributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
    }];

    // Dark theme
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        self.backgroundColor = CELL_BACKGROUND_COLOR;
        _commentTextView.backgroundColor = CELL_BACKGROUND_COLOR;

        for (UITextField *textField in arrayOfTextFields) {
            textField.backgroundColor = CELL_BACKGROUND_COLOR;
            textField.textColor = [UIColor whiteColor];
            textField.keyboardAppearance = UIKeyboardAppearanceDark;
        }

        _commentTextView.keyboardAppearance = UIKeyboardAppearanceDark;
        _commentTextView.textColor = [UIColor whiteColor];
    }

    // Captcha image will be in front of activity indicator after appearing.
    _captchaImage.layer.zPosition = 2;

    // Captch button will be in front of everything
    _captchaUpdateButton.layer.zPosition = 3;

    // Setup commentTextView appearance to look like textField.
    _commentTextView.delegate = self;

    // Delete textView insets.
    _commentTextView.textContainer.lineFragmentPadding = 0;
    _commentTextView.textContainerInset = UIEdgeInsetsMake(0.f, 15.f, 0., 15.f);

    // Setup dynamic font sizes.

    UIFont *defaultFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

    _captchaValueTextField.font = defaultFont;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_LITTLE_BODY_FONT]) {
        defaultFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    }

    _nameTextField.font = defaultFont;
    _subjectTextField.font = defaultFont;
    _emailTextField.font = defaultFont;

    _commentTextView.font = defaultFont;

    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(hideKeyBoard)];

    [self addGestureRecognizer:tapGesture];
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
    NSString *placeholder = NSLS(@"PLACEHOLDER_COMMENT_FIELD");

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

        // Dark theme
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
            textView.textColor = [UIColor whiteColor];
        }
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = NSLS(@"PLACEHOLDER_COMMENT_FIELD");
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
    [_captchaImage.layer removeAllAnimations];

    NSURLRequest *captchaRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                    cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                timeoutInterval:60.0];

    [_captchaImage setImageWithURLRequest:captchaRequest
                         placeholderImage:nil
                                  success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image)
    {
        // Dark theme
        if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
            CIFilter *filterInvert = [CIFilter filterWithName:@"CIColorInvert"];
            [filterInvert setDefaults];
            [filterInvert setValue:[[CIImage alloc] initWithCGImage:image.CGImage]
                            forKey:@"inputImage"];
            image = [[UIImage alloc] initWithCIImage:filterInvert.outputImage];

            CIFilter *filterBrightness= [CIFilter filterWithName:@"CIColorControls"];
            [filterBrightness setDefaults];
            [filterBrightness setValue:image.CIImage
                                forKey:@"inputImage"];
            [filterBrightness setValue:[NSNumber numberWithFloat:0.017]
                                forKey:@"inputBrightness"];
            image = [[UIImage alloc] initWithCIImage:filterBrightness.outputImage];
        }

        [UIView transitionWithView:_captchaImage
                          duration:0.5f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            _captchaImage.image = image;
                        } completion:NULL];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {

    }];
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

        // Insert close tag first because otherwise its position will change and we'll need to recalculate it
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

- (void)changeUploadViewToDeleteView:(UIView *)view andsetImage:(UIImage *)image forImageView:(UIImageView *)imageView
{
    [self layoutIfNeeded];
    // animate plus
    [UIView animateWithDuration:IMAGE_CHANGE_ANIMATE_TIME
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.autoresizesSubviews = NO;
                         [view setTransform:CGAffineTransformRotate(view.transform, M_PI/4)];
                         view.backgroundColor = [UIColor redColor];
                     } completion:nil];

    // animate image change
    [UIView transitionWithView:imageView
                      duration:IMAGE_CHANGE_ANIMATE_TIME
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        imageView.image = image;
                    } completion:NULL];
}

- (void)changeDeleteViewToUploadView:(UIView *)view andClearImageView:(UIImageView *)imageView
{
    [self layoutIfNeeded];
    // animate plus
    [UIView animateWithDuration:IMAGE_CHANGE_ANIMATE_TIME
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.autoresizesSubviews = NO;
                         [view setTransform:CGAffineTransformRotate(view.transform, -M_PI/4)];
                         view.backgroundColor = [UIColor clearColor];
                     } completion:nil];
    // animate image change
    [UIView transitionWithView:imageView
                      duration:IMAGE_CHANGE_ANIMATE_TIME
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        imageView.image = nil;
                    } completion:NULL];
}

@end
