//
//  DVBCreatePostViewController.h
//  dvach-browser
//
//  Created by Andy on 26/01/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DVBCreatePostViewControllerDelegate <NSObject>

@optional
/**
 *  Open thread after creating
 */
- (void)openThredWithCreatedThread:(NSString *)threadNum;
/**
 *  Update thread after posting
 */
- (void)updateThreadAfterPosting;

@end

@interface DVBCreatePostViewController : UIViewController

@property (nonatomic, weak) id<DVBCreatePostViewControllerDelegate> createPostViewControllerDelegate;
/**
 *  Board's shortcode
 */
@property (nonatomic, strong) NSString *boardCode;
/**
 *  OP number
 */
@property (nonatomic, strong) NSString *threadNum;

@end
