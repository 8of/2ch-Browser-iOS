//
//  DVBCaptchaViewController.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 13/09/15.
//  Copyright © 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DVBCaptchaViewControllerDelegate <NSObject>

- (void)captchaBeenChecked;

@end

@interface DVBCaptchaViewController : UIViewController

@property (nonatomic, weak) id<DVBCaptchaViewControllerDelegate> captchaViewControllerDelegate;

@end
