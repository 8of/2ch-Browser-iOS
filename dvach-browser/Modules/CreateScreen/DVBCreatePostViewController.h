//
//  DVBCreatePostViewController.h
//  dvach-browser
//
//  Created by Andy on 26/01/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DVBCommon.h"
#import "DVBCreatePostViewControllerDelegate.h"

@interface DVBCreatePostViewController : UIViewController

@property (nonatomic, weak) id<DVBCreatePostViewControllerDelegate> createPostViewControllerDelegate;
/// Board's shortcode
@property (nonatomic, strong) NSString *boardCode;
/// OP number
@property (nonatomic, strong) NSString *threadNum;

@end
