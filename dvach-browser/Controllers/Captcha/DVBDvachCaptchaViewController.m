//
//  DVBDvachCaptchaViewController.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 08/02/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <UIImageView+AFNetworking.h>

#import "DVBCommon.h"
#import "DVBConstants.h"
#import "DVBCaptchaManager.h"

#import "DVBDvachCaptchaViewController.h"

@interface DVBDvachCaptchaViewController ()

@property (nonatomic, strong) DVBCaptchaManager *captchaManager;
@property (nonatomic, strong) NSString *captchaId;

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UIButton *reloadButton;
@property (nonatomic, weak) IBOutlet UIButton *submitButton;

@end

@implementation DVBDvachCaptchaViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _captchaManager = [[DVBCaptchaManager alloc] init];
    [_reloadButton setTitle:@"" forState:UIControlStateNormal];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:SETTING_ENABLE_DARK_THEME]) {
        self.view.backgroundColor = CELL_BACKGROUND_COLOR;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self loadImage];
}

- (void)loadImage
{
    _imageView.image = nil;
    _textField.text = @"";
    [_captchaManager getCaptchaImageUrl:YES
                          andCompletion:^(NSString *captchaImageUrl, NSString *captchaId)
    {
        _captchaId = captchaId;
        [_imageView setImageWithURL:[NSURL URLWithString:captchaImageUrl]];
    }];
}

- (void)submitCaptcha
{
    [self.navigationController popViewControllerAnimated:YES];
    if (_dvachCaptchaViewControllerDelegate && [_dvachCaptchaViewControllerDelegate respondsToSelector:@selector(captchaBeenCheckedWithCode:andWithId:)]) {
        NSString *code = _textField.text;
        [_dvachCaptchaViewControllerDelegate captchaBeenCheckedWithCode:code
                                                              andWithId:_captchaId];
    }
}

#pragma mark - Actions

- (IBAction)reloadButtonAction:(id)sender
{
    [self loadImage];
}

- (IBAction)submitButtonAction:(id)sender
{
    [self submitCaptcha];
}

@end
