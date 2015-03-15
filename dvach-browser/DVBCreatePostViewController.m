//
//  DVBCreatePostViewController.m
//  dvach-browser
//
//  Created by Mega on 26/01/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "DVBConstants.h"
#import "DVBCreatePostViewController.h"
#import "DVBThreadViewController.h"
#import "Reachability.h"
#import "DVBComment.h"

@interface DVBCreatePostViewController () <UINavigationControllerDelegate,UIImagePickerControllerDelegate, UIAlertViewDelegate, UITextViewDelegate>

@property (nonatomic, strong) NSString *captchaKey;
@property (nonatomic, strong) NSString *captchaValue;
/**
 *  Usercode for posting without captcha
 */
@property (nonatomic, strong) NSString *usercode;
/**
 *  Image for sending (1).
 */
@property (strong, nonatomic) UIImage *imageToLoad;
/**
 *  Checker for including/excluding photo to query.
 */
@property (assign, nonatomic) BOOL isImagePicked;
@property (strong, nonatomic) NSString *createdThreadNum;
@property (strong, nonatomic) NSDictionary *captchaKeyGetDictionary;
@property (assign, nonatomic) BOOL postSuccessfull;

// UI elements
@property (weak, nonatomic) IBOutlet UIImageView *captchaImage;
@property (weak, nonatomic) IBOutlet UIButton *captchaUpdateButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *subjectTextField;
@property (weak, nonatomic) IBOutlet UITextField *captchaValueTextField;
@property (weak, nonatomic) IBOutlet UITextView *commentTextView;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;

// Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *captchaFieldHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fromThemeToCaptchaField;

@end

@implementation DVBCreatePostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareViewController];
    [self requestCaptchaKeyWithAddress:GET_CAPTCHA_KEY_URL andUsercode:_usercode];
}

/**
 *  All View Controller tuning
 */
- (void)prepareViewController
{
    /**
     *  Если threadNum is 0 - then we creating new thread and need to set View Controller's Title accordingly
     */
    if ([_threadNum isEqualToString:@"0"])
    {
        NSString *newThreadTitle = NSLocalizedString(@"Новый тред", @"Title of modal view controller if we creating thread");
        self.title = newThreadTitle;
    }
    /**
     *  Set comment from sharedComment
     */
    DVBComment *sharedComment = [DVBComment sharedComment];
    NSString *commentText = sharedComment.comment;
    
    if (![commentText isEqualToString:@""]) {
        _commentTextView.text = commentText;
    }
    
    /**
     *  commentTextView settings
     */
    _commentTextView.delegate = self;
    /**
     *  Setup commentTextView appearance to look like textField.
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
     *  Setup update button because of appearance
     */
    _captchaUpdateButton.adjustsImageWhenDisabled = YES;
    [_captchaUpdateButton sizeToFit];
    
    /**
     *  Prepare usercode from default
     */
    _usercode = [[NSUserDefaults standardUserDefaults] objectForKey:USERCODE];
    
    [self changeConstraints];
}

#pragma mark - Change constrints

- (void)changeConstraints {
    /**
     *  Turn off captcha fields if we have passcode
     */
    if (![_usercode isEqualToString:@""]) {
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
 *  Request captchaKey.
 */
- (void)requestCaptchaKeyWithAddress:(NSString *)address andUsercode:(NSString *)usercode
{
    
    AFHTTPSessionManager *captchaManager = [AFHTTPSessionManager manager];
     captchaManager.responseSerializer = [AFHTTPResponseSerializer serializer];
     [captchaManager.responseSerializer setAcceptableContentTypes:[NSSet setWithObject:@"text/plain"]];
    
    NSDictionary *params;
    
    if (usercode) {
        params = @{@"usercode":usercode};
    }
    
    [captchaManager GET:address
              parameters:params
                 success:^(NSURLSessionDataTask *task, id responseObject)
    {
         NSString *captchaKeyAnswer = [[NSString alloc] initWithData:responseObject
                                                            encoding:NSUTF8StringEncoding];
         if ([captchaKeyAnswer hasPrefix:@"CHECK"])
         {
             NSArray *arrayOfCaptchaKeyAnswers = [captchaKeyAnswer componentsSeparatedByString: @"\n"];
             
             NSString *captchaKey = [arrayOfCaptchaKeyAnswers lastObject];
             
             /**
              *  Set var for requesting Yandex key image now and posting later.
              */
             _captchaKey = captchaKey;
             
             NSString *urlOfYandexCaptchaImage = [[NSString alloc] initWithFormat:GET_CAPTCHA_IMAGE_URL, captchaKey];

             /**
              *  Present yandex captcha image to VC.
              */
             [_captchaImage sd_setImageWithURL:[NSURL URLWithString:urlOfYandexCaptchaImage]];

         }
        else if ([captchaKeyAnswer hasPrefix:@"VIP"])
        {
            NSLog(@"VIP passcode confirmed");
        }
    }
                 failure:^(NSURLSessionDataTask *task, NSError *error)
    {
        NSLog(@"Error: %@", error);
    }];
}

#pragma  mark - Actions

- (IBAction)captchaUpdateAction:(id)sender
{
    [self requestCaptchaKeyWithAddress:GET_CAPTCHA_KEY_URL andUsercode:_usercode];
    _captchaValueTextField.text = @"";
}

- (IBAction)makePostAction:(id)sender
{
    /**
     *  Dismiss keyboard before posting
     */
    [self.view endEditing:YES];
    
    NSString *name = _nameTextField.text;
    NSString *subject = _subjectTextField.text;
    NSString *comment = _commentTextView.text;
    NSString *captchaValue = _captchaValueTextField.text;
    
    [self postMessageWithTask:@"post"
                     andBoard:_boardCode
                 andThreadnum:_threadNum
                      andName:name
                     andEmail:@""
                   andSubject:subject
                   andComment:comment
                   andCaptcha:_captchaKey
              andcaptchaValue:captchaValue
                  andUsercode:_usercode
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
    [self goBackToThread];
}

/**
 *  Make post to thread.
 *
 *  @param task         <#task description#>
 *  @param board        <#board description#>
 *  @param threadNum    <#threadNum description#>
 *  @param name         <#name description#>
 *  @param email        <#email description#>
 *  @param subject      <#subject description#>
 *  @param comment      <#comment description#>
 *  @param captchaKey   <#captchaKey description#>
 *  @param captchaValue <#captchaValue description#>
 */
- (void)postMessageWithTask:(NSString *)task
                   andBoard:(NSString *)board
               andThreadnum:(NSString *)threadNum
                    andName:(NSString *)name
                   andEmail:(NSString *)email
                 andSubject:(NSString *)subject
                 andComment:(NSString *)comment
                 andCaptcha:(NSString *)captchaKey
            andcaptchaValue:(NSString *)captchaValue
                andUsercode:(NSString *)usercode
{
    
    /**
     *  Turn off POST button - so we can't tap it the second time before post action completed
     */
    self.navigationItem.rightBarButtonItem.enabled = FALSE;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSString *json = @"1";
    
    NSString *address = [[NSString alloc] initWithFormat:@"%@%@", DVACH_BASE_URL, @"makaba/posting.fcgi"];
    
    NSDictionary *params = @{
                             @"task":task,
                             @"json":json,
                             @"board":board,
                             @"thread":threadNum
                             };
    
    NSMutableDictionary *mutableParams = [params mutableCopy];
    
    /**
     *  Check userCode.
     */
    if (![_usercode isEqualToString:@""])
    {
        /**
         *  If usercode presented then use as part of the message.
         */
        NSLog(@"usercode way: %@", _usercode);
        [mutableParams setValue:_usercode forKey:@"usercode"];
    }
    else
    {
        /**
         *  Otherwise captcha.
         */
        [mutableParams setValue:captchaKey
                         forKey:@"captcha"];
        [mutableParams setValue:captchaValue
                         forKey:@"captcha_value"];
    }
    
    params = mutableParams;
    
    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects: @"application/json",nil]];
    
    [manager POST:address parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData)
    {
        
        /**
         *  Added comment field this way because makaba don't handle it right otherwise
         *  and name
         *  and subject
         */
        [formData appendPartWithFormData:[comment dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"comment"];
        [formData appendPartWithFormData:[name dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"name"];
        [formData appendPartWithFormData:[subject dataUsingEncoding:NSUTF8StringEncoding]
                                    name:@"subject"];
        
        /**
         *  Check if image present.
         */
        if (_imageToLoad) {
            NSData *fileData = UIImageJPEGRepresentation(_imageToLoad, 1.0);

             [formData appendPartWithFileData:fileData
                                         name:@"image1"
                                     fileName:@"image.jpg"
                                     mimeType:@"image/jpeg"];
        }

    }
          success:^(NSURLSessionDataTask *task, id responseObject)
    {
        
        NSString *responseString = [[NSString alloc] initWithData:responseObject
                                                         encoding:NSUTF8StringEncoding];
        NSLog(@"Success: %@", responseString);
        
        NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData
                                                                           options:0
                                                                             error:nil];
        /**
         *  Status field from response.
         */
        NSString *status = [responseDictionary objectForKey:@"Status"];
        
        /**
         *  Reason field from response.
         */
        NSString *reason = [responseDictionary objectForKey:@"Reason"];
        
        /**
         *  Compare answer to predefined values;
         */
        BOOL isOKanswer = [status isEqualToString:@"OK"];
        BOOL isRedirectAnswer = [status isEqualToString:@"Redirect"];
        
        if (isOKanswer || isRedirectAnswer)
        {
            /**
             *  If answer is good - make preparations in current ViewController
             */
            NSString *successTitle = NSLocalizedString(@"Успешно", @"Title of the createPostVC when post was successfull");
            self.title = successTitle;
            
            DVBComment *sharedComment = [DVBComment sharedComment];
            
            /**
             *  Clear saved comment if post was successfull.
             */
            _commentTextView.text = @"";
            sharedComment.comment = @"";
            
            self.navigationItem.rightBarButtonItem.enabled = FALSE;
            
            if (isRedirectAnswer)
            {
                NSString *threadNumToRedirect = [[responseDictionary objectForKey:@"Target"] stringValue];
                if (threadNumToRedirect)
                {
                    _createdThreadNum = threadNumToRedirect;
                }
                
            }
            [self performSelector:@selector(goBackToThread) withObject:nil afterDelay:2.0];
        }
        else
        {
            /**
             *  If post wasn't successful. Present alert with error code to user.
             */
            NSString *alertAboutPostTitle = NSLocalizedString(@"Ошибка", @"Alert Title of the createPostVC when post was NOT successful");
            
            UIAlertView *alertAboutPost = [[UIAlertView alloc] initWithTitle:alertAboutPostTitle message:reason delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertAboutPost setTag:0];
            [alertAboutPost show];
            self.navigationItem.rightBarButtonItem.enabled = TRUE;
        }

    }
          failure:^(NSURLSessionDataTask *task, NSError *error)
    {
        
        DVBComment *sharedComment = [DVBComment sharedComment];
        /**
         *  Saved comment if post was not successfull.
         */
        sharedComment.comment = _commentTextView.text;
        
        NSString *cancelTitle = NSLocalizedString(@"Ошибка", @"Title of the createPostVC when post was NOT successful");
        self.title = cancelTitle;
        NSLog(@"Error: %@", error);
        self.navigationItem.rightBarButtonItem.enabled = TRUE;
    }];
}

#pragma mark - UIMenuController and text tags

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    NSRange selectedRange = _commentTextView.selectedRange;
    NSUInteger selectedLength = selectedRange.length;
    if (selectedLength > 0) {
        NSLog(@"Selected text range loc: %lu, and length: %lu", (unsigned long)selectedRange.location, (unsigned long)selectedRange.length);
        /**
         *  turned off for future! do not delete
         */
        // [self makeMenu];
    }
    
}

/**
 *  Custom menu generator
 */
- (void)makeMenu
{
    UIMenuController *commentMenu = [UIMenuController sharedMenuController];
    
    UIMenuItem *boldItem = [[UIMenuItem alloc] initWithTitle:@"Жирный"
                                                      action:@selector(boldMenuItemACtion)];
    
    UIMenuItem *itelicItem = [[UIMenuItem alloc] initWithTitle:@"Наклонный"
                                                        action:@selector(italicMenuItemACtion)];
    
    commentMenu.menuItems = [[NSArray alloc] initWithObjects:boldItem, itelicItem, nil];
    [commentMenu setTargetRect:_commentTextView.bounds
                        inView:self.view];
    // [commentMenu update];
    commentMenu.menuVisible = TRUE;
}

/**
 *  Bold tags wrapping
 */
- (void)boldMenuItemACtion
{
    /**
     *  Future improvements for makaba markup will be here
     */
    NSLog(@"Fired bold!");
}

/**
 *  Italic tags wrapping
 */
- (void)italicMenuItemACtion
{
    /**
     *  Future improvements for makaba markup will be here
     */
    NSLog(@"Fired italic!");
}


#pragma mark - Image(s) picking

/**
 *  Pick picture from gallery.
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
 *  Delete all pointers to photo.
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

#pragma  mark - Alerts

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSInteger alertViewTag = alertView.tag;
    if (alertViewTag == 0) {
        [self requestCaptchaKeyWithAddress:GET_CAPTCHA_KEY_URL andUsercode:_usercode];
        _captchaValueTextField.text=@"";
    }
}

#pragma  mark - Navigation

- (void)goBackToThread
{
    NSString *threadNumberToCheck = _threadNum;
    if ([threadNumberToCheck isEqualToString:@"0"])
    {
        [self performSegueWithIdentifier:@"dismissWithCancelToNewThreadSegue"
                                  sender:self];
    }
    else
    {
        [self performSegueWithIdentifier:@"dismissWithCancelToThreadSegue"
                                  sender:self];
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    DVBComment *sharedComment = [DVBComment sharedComment];
    /**
     *  Save comment.
     */
    sharedComment.comment = _commentTextView.text;
    
    /**
     *  Xcode will complain if we access a weak property more than
     *  once here, since it could in theory be nilled between accesses
     *  leading to unpredictable results. So we'll start by taking
     *  a local, strong reference to the delegate.
     */
    id<DVBCreatePostViewControllerDelegate> strongDelegate = self.createPostViewControllerDelegate;
    
    if ([[segue identifier] isEqualToString:@"dismissWithCancelToThreadSegue"]) {

        /**
         *  Update thread in any case (was post successfull or not)
         *
         *  @param updateThreadAfterPosting <#updateThreadAfterPosting description#>
         *
         *  @return <#return value description#>
         */
        if ([strongDelegate respondsToSelector:@selector(updateThreadAfterPosting)])
        {
            [strongDelegate updateThreadAfterPosting];
        }
    }
    else if ([[segue identifier] isEqualToString:@"dismissWithCancelToNewThreadSegue"])
    {
        if (_createdThreadNum)
        {
            NSLog(@"New thread num: %@. Redirecting.", _createdThreadNum);
            /**
             *  Our delegate method is not optional, but we should check if delegate implements it anyway.
             */
            if ([strongDelegate respondsToSelector:@selector(openThredWithCreatedThread:)])
            {
                [strongDelegate openThredWithCreatedThread:_createdThreadNum];
            }
        }
    }
}

@end
