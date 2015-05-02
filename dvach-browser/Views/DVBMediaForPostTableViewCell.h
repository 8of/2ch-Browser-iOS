//
//  DVBMediaForPostTableViewCell.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 02/05/15.
//  Copyright (c) 2015 8of. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DVBThreadViewController.h"

@interface DVBMediaForPostTableViewCell : UITableViewCell

@property (nonatomic, strong) DVBThreadViewController *threadViewController;

- (void)prepareCellWithThumbPathesArray:(NSArray *)thumbPathesArray andPathesArray:(NSArray *)pathesArray;

@end
