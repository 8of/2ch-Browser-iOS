//
//  DVBCreatePostViewController.m
//  dvach-browser
//
//  Created by Andy on 26/01/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <Mantle/Mantle.h>
#import "UIImage+DVBImageExtention.h"

#import "DVBCommon.h"
#import "DVBConstants.h"
#import "Reachlibility.h"
#import "DVBNetworking.h"
#import "DVBPost.h"
#import "DVBComment.h"
#import "DVBMessagePostServerAnswer.h"

#import "DVBCreatePostViewController.h"
#import "DVBThreadViewController.h"
#import "DVBContainerForPostElements.h"
#import "DVBAddPhotoIconImageViewContainer.h"
#import "DVBPictureToSendPreviewImageView.h"

@interface DVBCreatePostViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) DVBNetworking *networking;
@property (nonatomic, strong) DVBComment *sharedComment;
/// Captcha
@property (nonatomic, strong) NSString *captchaValue;
/// Usercode for posting without captcha
@property (nonatomic, strong) NSString *usercode;
// Mutable array of UIImage objects we need to attach to post
@property (nonatomic, strong) NSMutableArray *imagesToUpload;
@property (nonatomic, strong) NSString *createdThreadNum;
@property (nonatomic, assign) BOOL postSuccessfull;

// UI elements
@property (nonatomic, weak) IBOutlet DVBContainerForPostElements *containerForPostElementsView;
@property (nonatomic, weak) IBOutlet UIScrollView *createPostScrollView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *sendPostButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *closeButton;
// Tempopary storage for add/remove picture button we just pressed
@property (nonatomic, strong) UIButton *addPictureButton;

@end

@implementation DVBCreatePostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prepareViewController];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self saveCommentForLater];
    [_containerForPostElementsView removeObservers];
}

/// All View Controller tuning
- (void)prepareViewController
{
    [self darkThemeHandler];
    _networking = [[DVBNetworking alloc] init];

    _closeButton.title = NSLS(@"BUTTON_CLOSE");
    _sendPostButton.title = NSLS(@"BUTTON_SEND");
    
    // If threadNum is 0 - then we creating new thread and need to set View Controller's Title accordingly.
    BOOL isThreadNumZero = [_threadNum isEqualToString:@"0"];
    if (isThreadNumZero) {
        self.title = NSLS(@"TITLE_NEW_THREAD");
    }
    // Set comment field text from sharedComment.
    _sharedComment = [DVBComment sharedComment];
    NSString *commentText = _sharedComment.comment;

    if ([commentText length] > 0) {
        _containerForPostElementsView.commentTextView.text = commentText;
    }
    else {
        _containerForPostElementsView.commentTextView.text = NSLS(@"PLACEHOLDER_COMMENT_FIELD");
        _containerForPostElementsView.commentTextView.textColor = [UIColor lightGrayColor];
    }
    
    // Prepare usercode (aka passcode) from default.
    _usercode = [[NSUserDefaults standardUserDefaults] objectForKey:USERCODE];
    
    if ([_usercode isEqualToString:@""]) {
        // Ask server for captcha if user code is not presented.
        [self requestCaptchaImage];
    }

    _imagesToUpload = [@[] mutableCopy];
    
    [self changeConstraints];
}

- (void)darkThemeHandler
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        self.view.backgroundColor = CELL_BACKGROUND_COLOR;
        _createPostScrollView.backgroundColor = CELL_BACKGROUND_COLOR;
    }
}

#pragma mark - Change constrints

- (void)changeConstraints
{
    // Remove captcha fields if we have passcode
    BOOL isUsercodeNotEmpty = ![_usercode isEqualToString:@""];
    
    if (isUsercodeNotEmpty) {
        [_containerForPostElementsView changeConstraintsIfUserCodeNotEmpty];
    }
}

#pragma mark - Captcha

/// Request captcha image (server key stores in networking.m)
- (void)requestCaptchaImage
{
    // Firstly we entirely hide captcha image until we have new image
    [_containerForPostElementsView clearCaptchaImage];
    
    [_networking requestCaptchaKeyWithCompletion:^(NSString *completion)
    {
        // Present yandex captcha image to VC
        [_containerForPostElementsView setCaptchaImageWithUrlString:completion];
        [_containerForPostElementsView clearCaptchaValueField];
    }];
}

#pragma  mark - Actions

/// Update captcha image
- (IBAction)captchaUpdateAction:(id)sender
{
    [self requestCaptchaImage];
    self.navigationItem.prompt = nil;
}

/// Button action to fire post sending method
- (IBAction)makePostAction:(id)sender
{
    // Dismiss keyboard before posting
    [self.view endEditing:YES];

    // Clear any prompt messages
    self.navigationItem.prompt = nil;
    
    // Get values from fields
    NSString *name = _containerForPostElementsView.nameTextField.text;
    NSString *subject = _containerForPostElementsView.subjectTextField.text;
    NSString *email = _containerForPostElementsView.emailTextField.text;
    NSString *comment = _containerForPostElementsView.commentTextView.text;
    NSString *captchaValue = _containerForPostElementsView.captchaValueTextField.text;

    NSArray *imagesToUpload = [_imagesToUpload copy];
    // Fire actual method
    [self postMessageWithTask:@"post"
                     andBoard:_boardCode
                 andThreadnum:_threadNum
                      andName:name
                     andEmail:email
                   andSubject:subject
                   andComment:comment
              andcaptchaValue:captchaValue
                  andUsercode:_usercode
            andImagesToUpload:imagesToUpload
     ];

}

- (IBAction)pickPhotoAction:(id)sender
{
    _addPictureButton = sender;

    UIImageView *imageViewToCheckImage = [self imageViewToShowUploadingImageWithArrayOfViews:_addPictureButton.superview.subviews];

    if (imageViewToCheckImage.image) {
        [self deletePicture];
    }
    else {
        [self pickPicture];
    }
}

- (IBAction)cancelPostAction:(id)sender
{
    // Dismiss keyboard before dismissing View Controller.
    [self.view endEditing:YES];
    // Fire actual dismissing method.
    [self goBackToThread];
}

/// Send post to thread (or create thread)
- (void)postMessageWithTask:(NSString *)task
                   andBoard:(NSString *)board
               andThreadnum:(NSString *)threadNum
                    andName:(NSString *)name
                   andEmail:(NSString *)email
                 andSubject:(NSString *)subject
                 andComment:(NSString *)comment
            andcaptchaValue:(NSString *)captchaValue
                andUsercode:(NSString *)usercode
          andImagesToUpload:(NSArray *)imagesToUpload
{
    
    // Turn off POST button
    _sendPostButton.enabled = NO;
    
    [_networking postMessageWithTask:task
                            andBoard:board
                        andThreadnum:threadNum
                             andName:name
                            andEmail:email
                          andSubject:subject
                          andComment:comment
                     andcaptchaValue:captchaValue
                         andUsercode:usercode
                   andImagesToUpload:imagesToUpload
                       andCompletion:^(DVBMessagePostServerAnswer *messagePostServerAnswer)

    {
        // Set Navigation prompt accordingly to server answer.
        NSString *serverStatusMessage = messagePostServerAnswer.statusMessage;
        self.navigationItem.prompt = serverStatusMessage;
        
        BOOL isPostWasSuccessful = messagePostServerAnswer.success;
        
        if (isPostWasSuccessful) {
            
            NSString *threadToRedirectTo = messagePostServerAnswer.threadToRedirectTo;
            BOOL isThreadToRedirectToNotEmpty = ![threadToRedirectTo isEqualToString:@""];
            
            if (threadToRedirectTo && isThreadToRedirectToNotEmpty) {
                _createdThreadNum = threadToRedirectTo;
            }

            // Clear comment text and saved comment if post was successfull.
            _containerForPostElementsView.commentTextView.text = @"";
            _sharedComment.comment = @"";

            // Dismiss View Controller if post was successfull.
            [self performSelector:@selector(goBackToThread)
                       withObject:nil
                       afterDelay:1.0];
        }
        else {
            // Enable Post button back.
            _sendPostButton.enabled = YES;
            [self requestCaptchaImage];
        }
    }];
}

#pragma mark - Image(s) picking

/// Pick picture from gallery
- (void)pickPicture
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker
                       animated:YES
                     completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:^{
        NSString *imageReferenceUrl = [info[UIImagePickerControllerReferenceURL] absoluteString];
        NSArray *imageReferenceUrlArray = [imageReferenceUrl componentsSeparatedByString: @"ext="];
        NSString *imageExtention = imageReferenceUrlArray.lastObject;

        UIImage *imageToLoad = info[UIImagePickerControllerOriginalImage];

        // Set image extention to prepare image the right way before uplaoding
        imageToLoad.imageExtention = imageExtention.lowercaseString;

        UIImageView *imageViewToShowIn = [self imageViewToShowUploadingImageWithArrayOfViews:_addPictureButton.superview.subviews];

        [_imagesToUpload addObject:imageToLoad];

        UIView *plusContainerView = [self viewPlusContainerWithArrayOfViews:_addPictureButton.superview.subviews];

        [_containerForPostElementsView changeUploadViewToDeleteView:plusContainerView andsetImage:imageToLoad forImageView:imageViewToShowIn];

        _addPictureButton = nil;
    }];


}

/// Delete all pointers/refs to photo.
- (void)deletePicture
{
    // _imageToLoad = nil;
    UIImageView *imageViewToDeleteIn = [self imageViewToShowUploadingImageWithArrayOfViews:_addPictureButton.superview.subviews];

    UIImage *imageToDeleteFromEverywhere = imageViewToDeleteIn.image;

    if (imageToDeleteFromEverywhere) {
        BOOL isImagePresentedInArray = [_imagesToUpload containsObject:imageToDeleteFromEverywhere];

        if (isImagePresentedInArray) {
            [_imagesToUpload removeObject:imageToDeleteFromEverywhere];
        }
    }

    UIView *plusContainerView = [self viewPlusContainerWithArrayOfViews:_addPictureButton.superview.subviews];

    [_containerForPostElementsView changeDeleteViewToUploadView:plusContainerView andClearImageView:imageViewToDeleteIn];
    _addPictureButton = nil;
}

/// Find image view to show image to upload in
- (DVBPictureToSendPreviewImageView *)imageViewToShowUploadingImageWithArrayOfViews:(NSArray *)arrayOfViews
{
    for (UIView *view in arrayOfViews) {
        BOOL isItImageView = [view isMemberOfClass:[DVBPictureToSendPreviewImageView class]];
        if (isItImageView) {
            DVBPictureToSendPreviewImageView *imageView = (DVBPictureToSendPreviewImageView *)view;

            return imageView;
        }
    }

    return nil;
}

/// Find image view's with PLUS icon container
- (UIView *)viewPlusContainerWithArrayOfViews:(NSArray *)arrayOfViews
{
    for (UIView *view in arrayOfViews) {
        BOOL isItImageView = [view isMemberOfClass:[DVBAddPhotoIconImageViewContainer class]];
        if (isItImageView) {

            return view;
        }
    }

    return nil;
}

#pragma  mark - Navigation

- (void)goBackToThread
{
    self.navigationItem.prompt = nil;
    BOOL isThreadNumZero = [_threadNum isEqualToString:@"0"];
    
    if (isThreadNumZero) {
        [self performSegueWithIdentifier:SEGUE_DISMISS_TO_NEW_THREAD
                                  sender:self];
    }
    else  {
        [self performSegueWithIdentifier:SEGUE_DISMISS_TO_THREAD
                                  sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    BOOL isSegueDismissToThread = [[segue identifier] isEqualToString:SEGUE_DISMISS_TO_THREAD];
    BOOL isSegueDismissToNewThread = [[segue identifier] isEqualToString:SEGUE_DISMISS_TO_NEW_THREAD];
    
    /**
     *  Xcode will complain if we access a weak property more than once here, since it could in theory be nilled between accesses
     *  leading to unpredictable results. So we'll start by taking a local, strong reference to the delegate.
     */
    id<DVBCreatePostViewControllerDelegate> strongDelegate = self.createPostViewControllerDelegate;
    
    if (isSegueDismissToThread) {
        // Update thread in any case (was post successfull or not)
        if ([strongDelegate respondsToSelector:@selector(updateThreadAfterPosting)]) {
            [strongDelegate updateThreadAfterPosting];
        }
    }
    else if (isSegueDismissToNewThread) {

        if (_createdThreadNum) {
            if ([strongDelegate respondsToSelector:@selector(openThredWithCreatedThread:)]) {
                [strongDelegate openThredWithCreatedThread:_createdThreadNum];
            }
        }
    }
}

/// Write comment text to singleton
- (void)saveCommentForLater
{
    // Save comment for later if it is not a placeholder.
    if (![_containerForPostElementsView.commentTextView.text isEqualToString:NSLS(@"PLACEHOLDER_COMMENT_FIELD")]) {
        _sharedComment.comment = _containerForPostElementsView.commentTextView.text;
    }
}

@end
