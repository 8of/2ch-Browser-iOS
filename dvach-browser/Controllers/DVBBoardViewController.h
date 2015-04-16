//
//  DVBBoardViewController.h
//  dvach-browser
//
//  View controller for displaying one board threads
//
//  Created by Andy on 05/10/14.
//  Copyright (c) 2014 8of. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DVBCreatePostViewController.h"

@interface DVBBoardViewController : UITableViewController

/**
 *  Board's shortcode.
 */
@property (strong, nonatomic) NSString *boardCode;
/**
 *  MaxPage (i.e. page count) for specific board.
 */
@property (assign, nonatomic) NSInteger pages;

@end
