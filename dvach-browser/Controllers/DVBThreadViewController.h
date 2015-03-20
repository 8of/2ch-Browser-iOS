//
//  DVBThreadViewController.h
//  dvach-browser
//
//  Created by Andy on 11/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DVBThreadViewController : UITableViewController
/**
 *  Board shortcode.
 */
@property (strong, nonatomic) NSString *boardCode;
/**
 *  Thread number
 */
@property (strong, nonatomic) NSString *threadNum;
/**
 *  Subject for section title in board View Controller.
 */
@property (strong, nonatomic) NSString *threadSubject;
/**
 *  For sending info when marking bad posts (need to update view controller content "remotely")
 */
@property (nonatomic, assign) id delegate;
/**
 *  Index of bad thread in threads' array (needed for just plain deleting element from array).
 */
@property (nonatomic, assign) NSUInteger threadIndex;
/**
 *  Reload thread by calling this method outside (like from posting View Controller after Posting new message).
 */
- (void)reloadThreadFromOutside;

@end
