//
//  DVBCreatePostViewController.m
//  dvach-browser
//
//  Created by Andy on 26/01/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <UINavigationItem+Loading.h>

#import "DVBConstants.h"
#import "Reachlibility.h"
#import "DVBNetworking.h"
#import "DVBComment.h"
#import "DVBMessagePostServerAnswer.h"

#import "DVBCreatePostViewController.h"
#import "DVBThreadViewController.h"

#import "DVBWrapMenuItem.h"
#import "DVBContainerForPostElements.h"

@interface DVBCreatePostViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

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
@property (weak, nonatomic) IBOutlet DVBContainerForPostElements *containerForPostElementsView;
@property (nonatomic, weak) IBOutlet UIScrollView *createPostScrollView;

@end

@implementation DVBCreatePostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prepareViewController];
}

/**
 *  All View Controller tuning
 */
- (void)prepareViewController
{
    _networking = [[DVBNetworking alloc] init];
    
    // If threadNum is 0 - then we creating new thread and need to set View Controller's Title accordingly.
    BOOL isThreadNumZero = [_threadNum isEqualToString:@"0"];
    if (isThreadNumZero) {
        NSString *newThreadTitle = NSLocalizedString(@"Новый тред", @"Title of modal view controller if we creating thread");
        self.title = newThreadTitle;
    }
    // Set comment field text from sharedComment.
    _sharedComment = [DVBComment sharedComment];
    NSString *commentText = _sharedComment.comment;

    if ([commentText length] > 0) {
        _containerForPostElementsView.commentTextView.text = commentText;
    }
    
    // Prepare usercode (aka passcode) from default.
    _usercode = [[NSUserDefaults standardUserDefaults] objectForKey:USERCODE];
    
    if ([_usercode isEqualToString:@""]) {
        // Ask server for captcha if user code is not presented.
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
    
    if (isUsercodeNotEmpty) {
        [_containerForPostElementsView changeConstraintsIfUserCodeNotEmpty];
    }
}

#pragma mark - Captcha

/**
 *  Request captcha image (server key stores in networking.m)
 */
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
    
    // Get values from fields
    NSString *name = _containerForPostElementsView.nameTextField.text;
    NSString *subject = _containerForPostElementsView.subjectTextField.text;
    NSString *comment = _containerForPostElementsView.commentTextView.text;
    NSString *captchaValue = _containerForPostElementsView.captchaValueTextField.text;
    
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
    if (!_isImagePicked) {
        [self pickPicture];
    }
    else {
        [self deletePicture];
    }
    
}

- (IBAction)cancelPostAction:(id)sender
{
    // Dismiss keyboard before dismissing View Controller.
    [self.view endEditing:YES];
    // Fire actual dismissing method.
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
    
    // Turn off POST button - so we can't tap it the second time before post action completed.
    [self.navigationItem startAnimatingAt:ANNavBarLoaderPositionRight];
    
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
        // Set Navigation prompt accordingly to server answer.
        NSString *serverStatusMessage = messagePostServerAnswer.statusMessage;
        self.navigationItem.prompt = serverStatusMessage;
        
        BOOL isPostWasSuccessful = messagePostServerAnswer.success;
        
        if (isPostWasSuccessful) {
            // Clear comment text and saved comment if post was successfull.
            _containerForPostElementsView.commentTextView.text = @"";
            _sharedComment.comment = @"";
            
            NSString *threadToRedirectTo = messagePostServerAnswer.threadToRedirectTo;
            BOOL isThreadToRedirectToNotEmpty = ![threadToRedirectTo isEqualToString:@""];
            
            if (isThreadToRedirectToNotEmpty) {
                _createdThreadNum = threadToRedirectTo;
            }
            // Dismiss View Controller if post was successfull.
            [self performSelector:@selector(goBackToThread)
                       withObject:nil
                       afterDelay:2.0];
        }
        else {
            // Enable Post button back.
            [self.navigationItem stopAnimating];
            [self requestCaptchaImage];
        }
    }];
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
    [self presentViewController:imagePicker
                       animated:YES
                     completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    _imageToLoad = info[UIImagePickerControllerOriginalImage];
    _isImagePicked = TRUE;
    
    [_containerForPostElementsView changeUploadButtonToDelete];
    
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

/**
 *  Delete all pointers/refs to photo
 */
- (void)deletePicture
{
    _imageToLoad = nil;
    _isImagePicked = FALSE;
    [_containerForPostElementsView changeUploadButtonToUpload];
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
    // Save comment for later.
    _sharedComment.comment = _containerForPostElementsView.commentTextView.text;
    
    BOOL isSegueDismissToThread = [[segue identifier] isEqualToString:SEGUE_DISMISS_TO_THREAD];
    BOOL isSegueDismissToNewThread = [[segue identifier] isEqualToString:SEGUE_DISMISS_TO_NEW_THREAD];
    
    /**
     *  Xcode will complain if we access a weak property more than once here, since it could in theory be nilled between accesses
     *  leading to unpredictable results. So we'll start by taking a local, strong reference to the delegate.
     */
    id<DVBCreatePostViewControllerDelegate> strongDelegate = self.createPostViewControllerDelegate;
    
    if (isSegueDismissToThread) {
        /**
         *  Update thread in any case (was post successfull or not)
         */
        if ([strongDelegate respondsToSelector:@selector(updateThreadAfterPosting)]) {
            [strongDelegate updateThreadAfterPosting];
        }
    }
    else if (isSegueDismissToNewThread) {

        if (_createdThreadNum) {
            NSLog(@"New thread num: %@. Redirecting.", _createdThreadNum);

            if ([strongDelegate respondsToSelector:@selector(openThredWithCreatedThread:)]) {
                [strongDelegate openThredWithCreatedThread:_createdThreadNum];
            }
        }
    }
}

@end
