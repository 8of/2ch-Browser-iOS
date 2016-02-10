//
//  DVBDvachCaptchaViewController.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 08/02/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DVBDvachCaptchaViewControllerDelegate <NSObject>

- (void)captchaBeenCheckedWithCode:(NSString *)code andWithId:(NSString *)captchaId;

@end

@interface DVBDvachCaptchaViewController : UIViewController

@property (nonatomic, weak) id<DVBDvachCaptchaViewControllerDelegate> dvachCaptchaViewControllerDelegate;

@end
