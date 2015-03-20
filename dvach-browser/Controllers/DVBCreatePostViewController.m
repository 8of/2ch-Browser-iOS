//
//  DVBCreatePostViewController.m
//  dvach-browser
//
//  Created by Andy on 26/01/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <IQKeyboardManager/IQKeyboardManager.h>
#import "DVBConstants.h"
#import "DVBCreatePostViewController.h"
#import "DVBThreadViewController.h"
#import "Reachability.h"
#import "DVBComment.h"
#import "DVBNetworking.h"
#import "DVBMessagePostServerAnswer.h"
#import "DVBWrapMenuItem.h"

@interface DVBCreatePostViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate>

@property (nonatomic, strong) DVBNetworking *networking;
@property (nonatomic, strong) DVBComment *sharedComment;
/**
 *  Captcha
 */
@property (nonatomic, strong) NSString *captchaValue;
/**
 *  Usercode for posting without captcha
 */
@property (nonatomic, strong) NSString *usercode;
/**
 *  Image for sending (1)
 */
@property (nonatomic, strong) UIImage *imageToLoad;
/**
 *  Checker for including/excluding photo to query
 */

@property (nonatomic, assign) BOOL isImagePicked;
@property (nonatomic, strong) NSString *createdThreadNum;
@property (nonatomic, assign) BOOL postSuccessfull;

// UI elements
@property (nonatomic, weak) IBOutlet UIImageView *captchaImage;
@property (nonatomic, weak) IBOutlet UIButton *captchaUpdateButton;
@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UITextField *subjectTextField;
@property (nonatomic, weak) IBOutlet UITextField *captchaValueTextField;
@property (nonatomic, weak) IBOutlet UITextView *commentTextView;
@property (nonatomic, weak) IBOutlet UIButton *uploadButton;

// Constraints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *captchaFieldHeight;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *fromThemeToCaptchaField;

@end

@implementation DVBCreatePostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prepareViewController];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // If user is on iPad
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        // Turn off viewController scrolling on textEdit focusing
        // need to rewrite this whole feature in future
        [[IQKeyboardManager sharedManager] setEnable:NO];
    }
}

/**
 *  All View Controller tuning
 */
- (void)prepareViewController
{
    _networking = [[DVBNetworking alloc] init];
    
    /**
     *  If threadNum is 0 - then we creating new thread and need to set View Controller's Title accordingly
     */
    BOOL isThreadNumZero = [_threadNum isEqualToString:@"0"];
    if (isThreadNumZero)
    {
        NSString *newThreadTitle = NSLocalizedString(@"Новый тред", @"Title of modal view controller if we creating thread");
        self.title = newThreadTitle;
    }
    /**
     *  Set comment field text from sharedComment
     */
    _sharedComment = [DVBComment sharedComment];
    NSString *commentText = _sharedComment.comment;
    _commentTextView.text = commentText;
    
    /**
     *  CommentTextView settings
     */
    _commentTextView.delegate = self;
    /**
     *  Setup commentTextView appearance to look like textField
     */
    [_commentTextView.layer setBackgroundColor: [[UIColor whiteColor] CGColor]];
    [_commentTextView.layer setBorderColor: [[[UIColor grayColor] colorWithAlphaComponent:0.2] CGColor]];
    [_commentTextView.layer setBorderWidth: 1.0];
    [_commentTextView.layer setCornerRadius:5.0f];
    [_commentTextView.layer setMasksToBounds:YES];
    [_commentTextView setTextContainerInset:UIEdgeInsetsMake(5, 5, 100, 5)];
    
    /**
     *  Setup dynamic font sizes
     */
    _nameTextField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _subjectTextField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _captchaValueTextField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _commentTextView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _captchaUpdateButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    /**
     *  Setup button appearance
     */
    _captchaUpdateButton.adjustsImageWhenDisabled = YES;
    [_captchaUpdateButton sizeToFit];
    
    /**
     *  Prepare usercode (aka passcode) from default
     */
    _usercode = [[NSUserDefaults standardUserDefaults] objectForKey:USERCODE];
    
    // Captcha image will be in front of activity indicator after appearing
    _captchaImage.layer.zPosition = 2;
    
    if ([_usercode isEqualToString:@""])
    {
        /**
         *  Ask server for captcha if user code is not presented
         */
        [self requestCaptchaImage];
    }
    
    [self changeConstraints];
}

#pragma mark - Change constrints

- (void)changeConstraints
{
    /**
     *  Remove captcha fields if we have passcode
     */
    BOOL isUsercodeNotEmpty = ![_usercode isEqualToString:@""];
    
    if (isUsercodeNotEmpty)
    {
        _captchaFieldHeight.constant = 0;
        _fromThemeToCaptchaField.constant = 0;
        
        [_captchaValueTextField removeConstraints:_captchaValueTextField.constraints];
        [_captchaValueTextField removeFromSuperview];
        
        [_captchaUpdateButton removeConstraints:_captchaUpdateButton.constraints];
        [_captchaUpdateButton removeFromSuperview];
    }
}

#pragma mark - Captcha

/**
 *  Request captcha image (server key stores in networking.m)
 */
- (void)requestCaptchaImage
{
    // Firstly we entirely hide captcha image until we have new image
    [_captchaImage setImage:nil];
    
    [_networking requestCaptchaKeyWithCompletion:^(NSString *completion)
    {
        /**
         *  Present yandex captcha image to VC
         */
        [_captchaImage sd_setImageWithURL:[NSURL URLWithString:completion]];
        _captchaValueTextField.text = @"";
    }];
}

#pragma  mark - Actions
/**
 *  Update captcha image
 */
- (IBAction)captchaUpdateAction:(id)sender
{
    [self requestCaptchaImage];
    self.navigationItem.prompt = nil;
}
/**
 *  Button action to fire post sending method
 */
- (IBAction)makePostAction:(id)sender
{
    /**
     *  Dismiss keyboard before posting
     */
    [self.view endEditing:YES];
    /**
     *  Clear any prompt messages
     */
    self.navigationItem.prompt = nil;
    
    /**
     *  Get values from fields
     */
    NSString *name = _nameTextField.text;
    NSString *subject = _subjectTextField.text;
    NSString *comment = _commentTextView.text;
    NSString *captchaValue = _captchaValueTextField.text;
    
    /**
     *  Fire actual method
     */
    [self postMessageWithTask:@"post"
                     andBoard:_boardCode
                 andThreadnum:_threadNum
                      andName:name
                     andEmail:@""
                   andSubject:subject
                   andComment:comment
              andcaptchaValue:captchaValue
                  andUsercode:_usercode
               andImageToLoad:_imageToLoad
     ];

}

- (IBAction)pickPhotoAction:(id)sender
{
    if (!_isImagePicked)
    {
        [self pickPicture];
    }
    else
    {
        [self deletePicture];
    }
    
}

- (IBAction)cancelPostAction:(id)sender
{
    /**
     *  Dismiss keyboard before dismissing View Controller
     */
    [self.view endEditing:YES];
    /**
     *  Fire actual dismissing method
     */
    [self goBackToThread];
}

/**
 *  Send post to thread (or create thread)
 */
- (void)postMessageWithTask:(NSString *)task
                   andBoard:(NSString *)board
               andThreadnum:(NSString *)threadNum
                    andName:(NSString *)name
                   andEmail:(NSString *)email
                 andSubject:(NSString *)subject
                 andComment:(NSString *)comment
            andcaptchaValue:(NSString *)captchaValue
                andUsercode:(NSString *)usercode
             andImageToLoad:(UIImage *)imageToLoad
{
    
    /**
     *  Turn off POST button - so we can't tap it the second time before post action completed
     */
    self.navigationItem.rightBarButtonItem.enabled = FALSE;
    
    [_networking postMessageWithTask:task
                            andBoard:board
                        andThreadnum:threadNum
                             andName:name
                            andEmail:email
                          andSubject:subject
                          andComment:comment
                     andcaptchaValue:captchaValue
                         andUsercode:usercode
                      andImageToLoad:imageToLoad
                       andCompletion:^(DVBMessagePostServerAnswer *messagePostServerAnswer)
    {
        /**
         *  Set Navigation prompt accordingly to server answer
         */
        NSString *serverStatusMessage = messagePostServerAnswer.statusMessage;
        self.navigationItem.prompt = serverStatusMessage;
        
        BOOL isPostWasSuccessful = messagePostServerAnswer.success;
        
        if (isPostWasSuccessful)
        {
            /**
             *  Clear comment text and saved comment if post was successfull
             */
            _commentTextView.text = @"";
            _sharedComment.comment = @"";
            
            NSString *threadToRedirectTo = messagePostServerAnswer.threadToRedirectTo;
            BOOL isThreadToRedirectToNotEmpty = ![threadToRedirectTo isEqualToString:@""];
            
            if (isThreadToRedirectToNotEmpty)
            {
                _createdThreadNum = threadToRedirectTo;
            }
            /**
             *  Dismiss View Controller if post was successfull
             */
            [self performSelector:@selector(goBackToThread)
                       withObject:nil
                       afterDelay:2.0];
        }
        else
        {
            /**
             *  Enable Post button back
             */
            self.navigationItem.rightBarButtonItem.enabled = TRUE;
            [self requestCaptchaImage];
        }
    }];
}

#pragma mark - UIMenuController and text tags

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    NSRange selectedRange = _commentTextView.selectedRange;
    NSUInteger selectedLocation = selectedRange.location;
    NSUInteger selectedLength = selectedRange.length;
    if (selectedLength > 0)
    {
        NSLog(@"Selected text range loc: %lu, and length: %lu", (unsigned long)selectedRange.location, (unsigned long)selectedRange.length);

        [self makeMenuWithSelectedLocation:selectedLocation
                          andSelectedRange:selectedLength];
    }
}

/**
 *  Custom menu generator
 */
- (void)makeMenuWithSelectedLocation:(NSUInteger)selectedLocation
                    andSelectedRange:(NSUInteger)selectedRange
{
    UIMenuController *commentMenu = [UIMenuController sharedMenuController];
    
    NSString *boldTitle = NSLocalizedString(@"Жирный", @"Title for Bold markup in custom UIMenu in Posting View Controller");
    DVBWrapMenuItem *boldItem = [[DVBWrapMenuItem alloc] initWithTitle:boldTitle
                                                      action:@selector(boldMenuItemAction:)];
    
    // need to add this only to the first menu because we always will be read this params from it
    boldItem.selectedLocation = selectedLocation;
    boldItem.selectedRange = selectedRange;
    
    NSString *italicTitle = NSLocalizedString(@"Наклонный", @"Title for Italic markup in custom UIMenu in Posting View Controller");
    DVBWrapMenuItem *italicItem = [[DVBWrapMenuItem alloc] initWithTitle:italicTitle
                                                                  action:@selector(italicMenuItemAction:)];
    
    NSString *spoilerTitle = NSLocalizedString(@"Спойлер", @"Title for Spoiler markup in custom UIMenu in Posting View Controller");
    DVBWrapMenuItem *spoilerItem = [[DVBWrapMenuItem alloc] initWithTitle:spoilerTitle
                                                                  action:@selector(spoilerMenuItemAction:)];
    
    NSString *undelrineTitle = NSLocalizedString(@"Подчёркнутый", @"Title for Underline markup in custom UIMenu in Posting View Controller");
    DVBWrapMenuItem *underlineItem = [[DVBWrapMenuItem alloc] initWithTitle:undelrineTitle
                                                                   action:@selector(underlineMenuItemAction:)];
    
    NSString *strikeTitle = NSLocalizedString(@"Зачёркнутый", @"Title for Strike markup in custom UIMenu in Posting View Controller");
    DVBWrapMenuItem *strikeItem = [[DVBWrapMenuItem alloc] initWithTitle:strikeTitle
                                                                     action:@selector(strikeMenuItemAction:)];
    
    commentMenu.menuItems = [[NSArray alloc] initWithObjects:boldItem, italicItem, spoilerItem, underlineItem, strikeItem, nil];
    [commentMenu update];
    commentMenu.menuVisible = TRUE;
}

// Bold menu item action
- (void)boldMenuItemAction:(id)sender
{
    [self wrapMenuItemActionWithSender:sender andTagToInsert:@"b"];
}
// Italic menu item action
- (void)italicMenuItemAction:(id)sender
{
    [self wrapMenuItemActionWithSender:sender andTagToInsert:@"i"];
}
// Spoiler menu item action
- (void)spoilerMenuItemAction:(id)sender
{
    [self wrapMenuItemActionWithSender:sender andTagToInsert:@"spoiler"];
}
// Undelrine menu item action
- (void)underlineMenuItemAction:(id)sender
{
    [self wrapMenuItemActionWithSender:sender andTagToInsert:@"u"];
}
// Strike menu item action
- (void)strikeMenuItemAction:(id)sender
{
    [self wrapMenuItemActionWithSender:sender andTagToInsert:@"s"];
}
/**
 *  Wrap comment in commentTextView
 */
- (void)wrapMenuItemActionWithSender:(id)sender
            andTagToInsert:(NSString *)tagToInsert
{
    //receive value of row here. The sender in iOS 7 is an instance of UIMenuController.
    UIMenuController *targetSender = (UIMenuController *)sender ;
    DVBWrapMenuItem *menuItem=(DVBWrapMenuItem *)[targetSender.menuItems firstObject];
    
    NSUInteger locationForOpenTag = menuItem.selectedLocation;
    NSUInteger locationForCloseTag = locationForOpenTag + menuItem.selectedRange;
    
    NSString *tagToinsertBefore = [NSString stringWithFormat:@"[%@]", tagToInsert];
    NSString *tagToinsertAfter = [NSString stringWithFormat:@"[/%@]", tagToInsert];
    
    NSMutableString *mutableCommentString = [NSMutableString stringWithString:_commentTextView.text];
    
    // Insiert close tag first because otherwise its position will change and we'll need to recalculate it
    [mutableCommentString insertString:tagToinsertAfter
                               atIndex:locationForCloseTag];
    [mutableCommentString insertString:tagToinsertBefore
                               atIndex:locationForOpenTag];
    
    NSString *newCommentString = mutableCommentString;
    
    _commentTextView.text = newCommentString;
}

#pragma mark - Image(s) picking

/**
 *  Pick picture from gallery
 */
- (void)pickPicture
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    _imageToLoad = info[UIImagePickerControllerOriginalImage];
    _isImagePicked = TRUE;
    
    [self changeUploadButtonToDelete];
    
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

/**
 *  Delete all pointers to photo
 */
- (void)deletePicture
{
    _imageToLoad = nil;
    _isImagePicked = FALSE;
    [self changeUploadButtonToUpload];
}

#pragma mark - Animation

- (void)changeUploadButtonToDelete
{
    [UIView animateWithDuration:0.5f
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.view.autoresizesSubviews = NO;
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
        self.view.autoresizesSubviews = NO;
        [_uploadButton setTransform:CGAffineTransformRotate(_uploadButton.transform, -M_PI/4)];
        _uploadButton.tintColor = [[[[UIApplication sharedApplication] delegate] window] tintColor];
    } completion:nil];
}

#pragma  mark - Navigation

- (void)goBackToThread
{
    self.navigationItem.prompt = nil;
    BOOL isThreadNumZero = [_threadNum isEqualToString:@"0"];
    
    if (isThreadNumZero)
    {
        [self performSegueWithIdentifier:SEGUE_DISMISS_TO_NEW_THREAD
                                  sender:self];
    }
    else
    {
        [self performSegueWithIdentifier:SEGUE_DISMISS_TO_THREAD
                                  sender:self];
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    /**
     *  Save comment
     */
    _sharedComment.comment = _commentTextView.text;
    
    BOOL isSegueDismissToThread = [[segue identifier] isEqualToString:SEGUE_DISMISS_TO_THREAD];
    BOOL isSegueDismissToNewThread = [[segue identifier] isEqualToString:SEGUE_DISMISS_TO_NEW_THREAD];
    
    /**
     *  Xcode will complain if we access a weak property more than once here, since it could in theory be nilled between accesses
     *  leading to unpredictable results. So we'll start by taking a local, strong reference to the delegate.
     */
    id<DVBCreatePostViewControllerDelegate> strongDelegate = self.createPostViewControllerDelegate;
    
    if (isSegueDismissToThread)
    {
        /**
         *  Update thread in any case (was post successfull or not)
         */
        if ([strongDelegate respondsToSelector:@selector(updateThreadAfterPosting)])
        {
            [strongDelegate updateThreadAfterPosting];
        }
    }
    else if (isSegueDismissToNewThread)
    {
        if (_createdThreadNum)
        {
            NSLog(@"New thread num: %@. Redirecting.", _createdThreadNum);
            /**
             *  Our delegate method is not optional, but we should check if delegate implements it anyway
             */
            if ([strongDelegate respondsToSelector:@selector(openThredWithCreatedThread:)])
            {
                [strongDelegate openThredWithCreatedThread:_createdThreadNum];
            }
        }
    }
}

@end
