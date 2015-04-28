//
//  DVBContainerForPostElements.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 26/04/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface DVBContainerForPostElements : UIView

// UI elements
@property (nonatomic, weak) IBOutlet UITextView *commentTextView;
@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UITextField *subjectTextField;
@property (nonatomic, weak) IBOutlet UITextField *emailTextField;
@property (nonatomic, weak) IBOutlet UITextField *captchaValueTextField;

- (void)changeConstraintsIfUserCodeNotEmpty;
- (void)clearCaptchaValueField;

// Captcha stuff
- (void)clearCaptchaImage;
- (void)setCaptchaImageWithUrlString:(NSString *)urlString;

// Animate upload/delete button
- (void)changeUploadButtonToDelete;
- (void)changeUploadButtonToUpload;

@end
