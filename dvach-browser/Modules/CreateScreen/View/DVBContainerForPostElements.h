//
//  DVBContainerForPostElements.h
//  dvach-browser
//
//  Created by Andy on 26/04/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DVBContainerForPostElements : UIView

// UI elements
@property (nonatomic, weak) IBOutlet UITextView *commentTextView;
@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UITextField *subjectTextField;
@property (nonatomic, weak) IBOutlet UITextField *emailTextField;

// Animate upload/delete button
- (void)changeUploadViewToDeleteView:(UIView *)view andsetImage:(UIImage *)image forImageView:(UIImageView *)imageView;
- (void)changeDeleteViewToUploadView:(UIView *)view andClearImageView:(UIImageView *)imageView;

@end
