//
//  DVBDvachCaptchaViewController.h
//  dvach-browser
//
//  Created by Andy on 08/02/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DVBCommon.h"

@protocol DVBDvachCaptchaViewControllerDelegate <NSObject>

- (void)captchaBeenCheckedWithCode:(NSString * _Nonnull)code andWithId:(NSString * _Nonnull)captchaId;

@end

@interface DVBDvachCaptchaViewController : UIViewController

@property (nonatomic, weak, nullable) id<DVBDvachCaptchaViewControllerDelegate> dvachCaptchaViewControllerDelegate;
@property (nonatomic, strong, nullable) NSString *threadNum;

@end
