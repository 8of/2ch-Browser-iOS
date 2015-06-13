//
//  DVBContainerForPostElements.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 26/04/15.
//  Copyright (c) 2015 8of. All rights reserved.
//
#import <CoreImage/CoreImage.h>
#import <UIImageView+AFNetworking.h>

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

    [self registerForKeyboardNotifications];
}

- (void)setupAppearance
{
    // Dark theme
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        self.backgroundColor = CELL_BACKGROUND_COLOR;
        _commentTextView.backgroundColor = CELL_BACKGROUND_COLOR;
        _nameTextField.backgroundColor = CELL_BACKGROUND_COLOR;
        _subjectTextField.backgroundColor = CELL_BACKGROUND_COLOR;
        _emailTextField.backgroundColor = CELL_BACKGROUND_COLOR;
        _captchaValueTextField.backgroundColor = CELL_BACKGROUND_COLOR;

        NSString *subjectPlaceholder = NSLocalizedString(@"Тема", @"Placeholder для поля Тема");
        NSString *namePlaceholder = NSLocalizedString(@"Имя", @"Placeholder для поля Имя");
        NSString *emailPlaceholder = NSLocalizedString(@"Email", @"Placeholder для поля Email");
        NSString *captchaPlaceholder = NSLocalizedString(@"Капча", @"Placeholder для поля Капча");

        _subjectTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:subjectPlaceholder
                                                                                  attributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
        _subjectTextField.textColor = [UIColor whiteColor];
        _subjectTextField.keyboardAppearance = UIKeyboardAppearanceDark;

        _nameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:namePlaceholder
                                                                               attributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
        _nameTextField.textColor = [UIColor whiteColor];
        _nameTextField.keyboardAppearance = UIKeyboardAppearanceDark;

        _emailTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:emailPlaceholder
                                                                                attributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
        _emailTextField.textColor = [UIColor whiteColor];
        _emailTextField.keyboardAppearance = UIKeyboardAppearanceDark;

        _captchaValueTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:captchaPlaceholder
                                                                                       attributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
        _captchaValueTextField.textColor = [UIColor whiteColor];
        _captchaValueTextField.keyboardAppearance = UIKeyboardAppearanceDark;

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

    // [_commentTextView becomeFirstResponder];
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

#pragma mark - Keyboard
- (void)registerForKeyboardNotifications
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWasShown:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillBeHidden:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
}
- (void)removeObservers
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {

    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIKeyboardDidShowNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIKeyboardWillHideNotification
                                                      object:nil];
    }
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    DVBCreatePostScrollView *scrollView = (DVBCreatePostScrollView *)self.superview;
    if (!_originalInsets.top) {
        _originalInsets = scrollView.contentInset;
    }

    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGSize keyboardSize = [[[aNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight ) {
        CGSize origKeySize = keyboardSize;
        keyboardSize.height = origKeySize.width;
        keyboardSize.width = origKeySize.height;
    }
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(_originalInsets.top, 0, keyboardSize.height, 0);

    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    DVBCreatePostScrollView *scrollView = (DVBCreatePostScrollView *)self.superview;
    scrollView.contentInset = _originalInsets;
    scrollView.scrollIndicatorInsets = _originalInsets;
}

@end
