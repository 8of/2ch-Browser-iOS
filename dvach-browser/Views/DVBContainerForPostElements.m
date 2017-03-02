//
//  DVBContainerForPostElements.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 26/04/15.
//  Copyright (c) 2015 8of. All rights reserved.
//
#import <CoreImage/CoreImage.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

#import "DVBCommon.h"
#import "DVBConstants.h"

#import "DVBContainerForPostElements.h"
#import "DVBCreatePostScrollView.h"

static CGFloat const IMAGE_CHANGE_ANIMATE_TIME = 0.3f;

@interface DVBContainerForPostElements () <UITextViewDelegate>

// Values for  markup
@property (nonatomic, assign) NSUInteger commentViewSelectedStartLocation;
@property (nonatomic, assign) NSUInteger commentViewSelectedLength;
@property (nonatomic, assign) NSUInteger commentViewNeedToSetCarretToPosition;

@end

@implementation DVBContainerForPostElements

- (void)awakeFromNib
{
    [super awakeFromNib];
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
      _emailTextField
    ];

    NSArray *textFieldPlaceholders = @
    [
      NSLS(@"FIELD_POST_THEME"),
      NSLS(@"FIELD_POST_NAME"),
      NSLS(@"FIELD_POST_EMAIL")
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

    // Setup commentTextView appearance to look like textField.
    _commentTextView.delegate = self;

    // Delete textView insets.
    _commentTextView.textContainer.lineFragmentPadding = 0;
    _commentTextView.textContainerInset = UIEdgeInsetsMake(0.f, 15.f, 0., 15.f);

    // Setup dynamic font sizes.

    UIFont *defaultFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];

    _nameTextField.font = defaultFont;
    _subjectTextField.font = defaultFont;
    _emailTextField.font = defaultFont;

    _commentTextView.font = defaultFont;

    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(hideKeyBoard)];

    [self addGestureRecognizer:tapGesture];
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

/// Wrap comment in commentTextView
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
