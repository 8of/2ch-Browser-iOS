//
//  DVBDvachCaptchaViewController.m
//  dvach-browser
//
//  Created by Andrey Konstantinov on 08/02/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <AFNetworking/UIImageView+AFNetworking.h>

#import "DVBConstants.h"
#import "DVBCaptchaManager.h"
#import "DVBDefaultsManager.h"

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

    if ([DVBDefaultsManager isDarkMode]) {
        self.view.backgroundColor = CELL_BACKGROUND_COLOR;
        _textField.backgroundColor = CELL_BACKGROUND_COLOR;
        _textField.textColor = [UIColor whiteColor];
        _textField.keyboardAppearance = UIKeyboardAppearanceDark;

        _textField.layer.cornerRadius = 8.;
        _textField.layer.masksToBounds = YES;
        _textField.layer.borderColor = [[UIColor lightGrayColor]CGColor];
        _textField.layer.borderWidth = 1.;
    }

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [_textField becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self loadImage];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_textField resignFirstResponder];
}

- (void)loadImage
{
    _imageView.image = nil;
    _textField.text = @"";
    weakify(self);
    [_captchaManager getCaptchaImageUrl:_threadNum
                          andCompletion:^(NSString *captchaImageUrl, NSString *captchaId)
    {
        strongify(self);
        if (!self) { return; }
        self.captchaId = captchaId;
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:captchaImageUrl]];
        weakify(self);
        [self.imageView setImageWithURLRequest:request
                          placeholderImage:nil
                                   success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
                                       strongify(self);
                                       if (!self) { return; }
                                       if ([DVBDefaultsManager isDarkMode]) {
                                           self.imageView.image = [self inverseColor:image];
                                       } else {
                                           self.imageView.image = image;
                                       }
                                   }
                                   failure:nil];
        }];
}

#pragma mark - Private image stuff

- (UIImage *)inverseColor:(UIImage *)image
{
    CIImage *coreImage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    [filter setValue:coreImage forKey:kCIInputImageKey];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];

    CIFilter *filterBrightness = [CIFilter filterWithName:@"CIColorControls"];
    [filterBrightness setValue:result forKey:kCIInputImageKey];
    [filterBrightness setValue:[NSNumber numberWithFloat:0.017] forKey:kCIInputBrightnessKey];
    result = [filterBrightness valueForKey:kCIOutputImageKey];

    return [UIImage imageWithCIImage:result];
}

- (void)submitCaptcha
{
    [self.navigationController popViewControllerAnimated:YES];
    if (_dvachCaptchaViewControllerDelegate && [_dvachCaptchaViewControllerDelegate respondsToSelector:@selector(captchaBeenCheckedWithCode:andWithId:)]) {
        NSString *code = _textField.text;
        if (!code || !_captchaId) { return; }
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
