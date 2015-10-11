//
//  DVBPostTableViewCell.m
//  dvach-browser
//
//  Created by Andy on 13/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <UIImageView+AFNetworking.h>

#import "DVBConstants.h"
#import "DVBUrlRequestHelper.h"

#import "DVBPostTableViewCell.h"
#import "DVBWebmIconImageView.h"

@interface DVBPostTableViewCell () <UITextViewDelegate>

/// Title
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

// Media
@property (nonatomic, strong) NSArray *pathesArray;

// Post thumnails
@property (nonatomic, weak) IBOutlet UIImageView *postThumb0;
@property (nonatomic, weak) IBOutlet UIImageView *postThumb1;
@property (nonatomic, weak) IBOutlet UIImageView *postThumb2;
@property (nonatomic, weak) IBOutlet UIImageView *postThumb3;

// WebmIcons
@property (nonatomic, weak) IBOutlet UIImageView *postWebmIcon0;
@property (nonatomic, weak) IBOutlet UIImageView *postWebmIcon1;
@property (nonatomic, weak) IBOutlet UIImageView *postWebmIcon2;
@property (nonatomic, weak) IBOutlet UIImageView *postWebmIcon3;

// Media constraints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mediaTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mediaHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mediaHeightIpadConstraint;

// Media - constraint storages of initial values
@property (nonatomic, assign) CGFloat mediaHeightConstraintStorage;

// Actual post

// Thumbnail url
@property (nonatomic, strong) NSString *fullPathUrlString;
// TextView for post comment
@property (nonatomic, weak) IBOutlet UITextView *commentTextView;
// Post thumbnail
@property (nonatomic, weak) IBOutlet UIImageView *postThumb;

// Constraints - image
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *imageLeftConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *imageWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *imageHeightConstraint;

// Constraints - image - additional for iPad
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *imageWidthConstraintIPAD;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *imageHeightConstraintIPAD;

// Constraints - video-icon
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *videoiconWidthContstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *videoiconHeightContstraint;

// Constraint storages of initial values
@property (nonatomic, assign) CGFloat imageLeftConstraintStorage;
@property (nonatomic, assign) CGFloat imageWidthConstraintStorage;
@property (nonatomic, assign) CGFloat imageHeightConstraintStorage;
@property (nonatomic, assign) CGFloat videoiconWidthContstraintStorage;
@property (nonatomic, assign) CGFloat videoiconHeightContstraintStorage;


// Action buttons

/// Create answer for post button
@property (nonatomic, weak) IBOutlet UIButton *answerToPostButton;
/// Create answer for post with quote button
@property (nonatomic, weak) IBOutlet UIButton *answerToPostWithQuoteButton;
/// Show answer to post button
@property (nonatomic, weak) IBOutlet UIButton *showAnswersButton;

@end

@implementation DVBPostTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    _showAnswersButton.hidden = YES;

    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.layer.masksToBounds = NO;
    _titleLabel.opaque = YES;
    _titleLabel.backgroundColor = [UIColor whiteColor];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_LITTLE_BODY_FONT]) {
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    }
    
    _commentTextView.delegate = self;
    _imageLeftConstraintStorage = _imageLeftConstraint.constant;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _imageWidthConstraintStorage = _imageWidthConstraintIPAD.constant;
        _imageHeightConstraintStorage = _imageHeightConstraintIPAD.constant;

        _mediaHeightConstraintStorage = _mediaHeightIpadConstraint.constant;
        _mediaHeightIpadConstraint.constant = 0;
    } else {
        _imageWidthConstraintStorage = _imageWidthConstraint.constant;
        _imageHeightConstraintStorage = _imageHeightConstraint.constant;

        _mediaHeightConstraintStorage = _mediaHeightConstraint.constant;
        _mediaHeightConstraint.constant = 0;
    }

    _mediaTopConstraint.constant = 0;

    _videoiconWidthContstraintStorage = _videoiconWidthContstraint.constant;
    _videoiconHeightContstraintStorage = _videoiconHeightContstraint.constant;

    // for more tidy images and keep aspect ratio
    _postThumb.contentMode = UIViewContentModeScaleAspectFill;
    _postThumb.clipsToBounds = YES;
    [self rebuildPostThumbImageWithImagePresence:NO
                        andWithVideoIconPresence:NO];

    // set minimum delay before textView recognize tap on link
    _commentTextView.delaysContentTouches = NO;

    // Delete insets
    _commentTextView.textContainer.lineFragmentPadding = 0;
    _commentTextView.textContainerInset = UIEdgeInsetsZero;
    _commentTextView.opaque = YES;

    // It'll not become truly opaque otherwise
    for (UIView *subview in _commentTextView.subviews) {
        subview.opaque = YES;
        subview.backgroundColor = [UIColor whiteColor];
    }

    // Media

    _postWebmIcon0.hidden = YES;
    _postWebmIcon1.hidden = YES;
    _postWebmIcon2.hidden = YES;
    _postWebmIcon3.hidden = YES;

    _postThumb0.image = nil;
    _postThumb1.image = nil;
    _postThumb2.image = nil;
    _postThumb3.image = nil;

    _postThumb0.contentMode = UIViewContentModeScaleAspectFill;
    _postThumb0.clipsToBounds = YES;
    _postThumb1.contentMode = UIViewContentModeScaleAspectFill;
    _postThumb1.clipsToBounds = YES;
    _postThumb2.contentMode = UIViewContentModeScaleAspectFill;
    _postThumb2.clipsToBounds = YES;
    _postThumb3.contentMode = UIViewContentModeScaleAspectFill;
    _postThumb3.clipsToBounds = YES;

    // Dark theme handling
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        self.backgroundColor = CELL_BACKGROUND_COLOR;

        _titleLabel.textColor = CELL_TEXT_COLOR;
        _titleLabel.backgroundColor = CELL_BACKGROUND_COLOR;

        _postThumb0.superview.backgroundColor = CELL_BACKGROUND_COLOR;
        _postThumb1.superview.backgroundColor = CELL_BACKGROUND_COLOR;
        _postThumb2.superview.backgroundColor = CELL_BACKGROUND_COLOR;
        _postThumb3.superview.backgroundColor = CELL_BACKGROUND_COLOR;

        _commentTextView.backgroundColor = CELL_BACKGROUND_COLOR;

        // Hack to make it truly opaque
        for (UIView *subview in _commentTextView.subviews) {
            subview.backgroundColor = CELL_BACKGROUND_COLOR;
        }
    }
}

- (void)prepareCellWithTitle:(NSString *)title andCommentText:(NSAttributedString *)commentText andWithPostRepliesCount:(NSUInteger)postRepliesCount andIndex:(NSUInteger)index andDisableActionButton:(BOOL)disableActionButton andThumbPathesArray:(NSArray *)thumbPathesArray andPathesArray:(NSArray *)pathesArray
{
    _titleLabel.text = title;

    _pathesArray = pathesArray;

    // 4 Media images/icons
    if (pathesArray && ([pathesArray count] > 1)) {
        _mediaTopConstraint.constant = _imageLeftConstraintStorage;

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            _mediaHeightIpadConstraint.constant = _mediaHeightConstraintStorage;
        } else {
            _mediaHeightConstraint.constant = _mediaHeightConstraintStorage;
        }

        NSUInteger currentImageIndex = 0;

        for (NSString *postThumbUrlString in thumbPathesArray) {

            UIImageView *postThumb = [self valueForKey:[@"postThumb" stringByAppendingString:[NSString stringWithFormat:@"%ld", (unsigned long)currentImageIndex]]];

            __weak typeof(UIImageView *)weakPostThumb = postThumb;
            [postThumb setImageWithURLRequest:[DVBUrlRequestHelper urlRequestForUrlString:postThumbUrlString]
                             placeholderImage:nil
                                      success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nonnull response, UIImage * _Nonnull image)
             {
                 weakPostThumb.image = image;
             } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nonnull response, NSError * _Nonnull error) { }];

            DVBWebmIconImageView *webmIconImageView = [self imageViewToShowWebmIconWithArrayOfViews:postThumb.superview.subviews];

            if (webmIconImageView) {
                NSString *pathString = pathesArray[currentImageIndex];
                if ([self isMediaTypeWebmWithPicPath:pathString]) {
                    webmIconImageView.hidden = NO;
                }
            }
            
            currentImageIndex++;
        }
    } else if (thumbPathesArray && ([thumbPathesArray count] == 1)) {
        // load the image and setting image source depending on presented image or set blank image
        __weak typeof(UIImageView *)weakPostThumb = _postThumb;
        [_postThumb setImageWithURLRequest:[DVBUrlRequestHelper urlRequestForUrlString:thumbPathesArray[0]]
                          placeholderImage:[UIImage imageNamed:FILENAME_THUMB_IMAGE_PLACEHOLDER]
                                   success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nonnull response, UIImage * _Nonnull image)
         {
             weakPostThumb.image = image;
         } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nonnull response, NSError * _Nonnull error) { }];

        BOOL isThumbForWebm = [self isMediaTypeWebmWithPicPath:pathesArray[0]];
        [self rebuildPostThumbImageWithImagePresence:YES
                            andWithVideoIconPresence:isThumbForWebm];

        _fullPathUrlString = pathesArray[0];
    }


    // Set comment text
    _commentTextView.attributedText = commentText;


    // Answers buttons

    NSString *answerButtonTitle;

    if (postRepliesCount > 0) {
        answerButtonTitle = [NSString stringWithFormat:@"%ld", (unsigned long)postRepliesCount];
        _showAnswersButton.enabled = YES;
        _showAnswersButton.hidden = NO;
        [_showAnswersButton setTitle:answerButtonTitle
                       forState:UIControlStateNormal];
        _showAnswersButton.tag = index;
    }

    if (disableActionButton) {
        [_answerToPostButton setEnabled:NO];
        [_answerToPostWithQuoteButton setEnabled:NO];
    }
    else {
        _answerToPostButton.tag = index;
        _answerToPostWithQuoteButton.tag = index;
    }
}

- (void)rebuildPostThumbImageWithImagePresence:(BOOL)isImagePresent andWithVideoIconPresence:(BOOL)videoIconPresentce
{
    if (isImagePresent) {
        _imageLeftConstraint.constant = _imageLeftConstraintStorage;

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            _imageWidthConstraintIPAD.constant = _imageWidthConstraintStorage;
            _imageHeightConstraintIPAD.constant = _imageHeightConstraintStorage;
        }
        else {
            _imageWidthConstraint.constant = _imageWidthConstraintStorage;
            _imageHeightConstraint.constant = _imageWidthConstraintStorage;
        }
    }
    else {
        _imageLeftConstraint.constant = 0;

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            _imageWidthConstraintIPAD.constant = 0;
            _imageHeightConstraintIPAD.constant = 0;
        }
        else {
            _imageWidthConstraint.constant = 0;
            _imageHeightConstraint.constant = 0;
        }
    }

    if (videoIconPresentce) {
        _videoiconWidthContstraint.constant = _videoiconWidthContstraintStorage;
        _videoiconHeightContstraint.constant = _videoiconHeightContstraintStorage;
    }
    else {
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

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    _commentTextView.text = nil;
    _commentTextView.attributedText = nil;


    [_postThumb setImage:nil];
    [self rebuildPostThumbImageWithImagePresence:NO
                        andWithVideoIconPresence:NO];
    
    _imageLeftConstraint.constant = 0;

    _mediaTopConstraint.constant = 0;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _imageWidthConstraintIPAD.constant = 0;
        _imageHeightConstraintIPAD.constant = 0;

        _mediaHeightIpadConstraint.constant = 0;
    }
    else {
        _imageWidthConstraint.constant = 0;
        _imageHeightConstraint.constant = 0;

        _mediaHeightConstraint.constant = 0;
    }

    _postWebmIcon0.hidden = YES;
    _postWebmIcon1.hidden = YES;
    _postWebmIcon2.hidden = YES;
    _postWebmIcon3.hidden = YES;

    _postThumb0.image = nil;
    _postThumb1.image = nil;
    _postThumb2.image = nil;
    _postThumb3.image = nil;

    _showAnswersButton.enabled = NO;
    _showAnswersButton.hidden = YES;
    [_showAnswersButton setTitle:nil
                        forState:UIControlStateNormal];

    [_answerToPostButton setEnabled:YES];
    [_answerToPostWithQuoteButton setEnabled:YES];
    
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

        [_threadViewController callShareControllerWithUrlString:[URL absoluteString]];
    }

    return NO;
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

// Check if this webm link
- (BOOL)isMediaTypeWebmWithPicPath:(NSString *)picPath
{
    BOOL isContainWebm = ([picPath rangeOfString:@".webm" options:NSCaseInsensitiveSearch].location != NSNotFound);

    return isContainWebm;
}

- (DVBWebmIconImageView *)imageViewToShowWebmIconWithArrayOfViews:(NSArray *)arrayOfViews
{
    for (UIView *view in arrayOfViews) {
        BOOL isItImageView = [view isMemberOfClass:[DVBWebmIconImageView class]];
        if (isItImageView) {
            DVBWebmIconImageView *imageView = (DVBWebmIconImageView *)view;

            return imageView;
        }
    }

    return nil;
}

- (void)openMediaWithMediaIndex:(NSUInteger)index
{
    if (_threadViewController && (index < [_pathesArray count])) {
        NSString *urlString = _pathesArray[index];
        if (urlString) {
            [_threadViewController openMediaWithUrlString:urlString];
        }
    }
}

#pragma mark - Actions

- (IBAction)touchFirstPicture:(id)sender
{
    [_threadViewController openMediaWithUrlString:_fullPathUrlString];
}

- (IBAction)touchFirstMedia:(id)sender
{
    [self openMediaWithMediaIndex:0];
}

- (IBAction)touchSecondMedia:(id)sender
{
    [self openMediaWithMediaIndex:1];
}

- (IBAction)touchThirdMedia:(id)sender
{
    [self openMediaWithMediaIndex:2];
}

- (IBAction)touchFourthMedia:(id)sender
{
    [self openMediaWithMediaIndex:3];
}

@end
