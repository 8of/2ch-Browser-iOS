//
//  DVBAsyncBoardViewController.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 15/11/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface DVBAsyncBoardViewController : ASViewController

- (instancetype)initBoardCode:(NSString *)boardCode pages:(NSInteger)pages;

@end
