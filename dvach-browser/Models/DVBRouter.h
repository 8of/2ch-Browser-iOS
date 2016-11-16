//
//  DVBRouter.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 16/11/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "DVBThread.h"

@interface DVBRouter : NSObject

+ (void)pushBoardFrom:(UIViewController *)viewController boardCode:(NSString *)boardCode pages:(NSInteger)pages;
+ (void)pushThreadFrom:(UIViewController *)viewController withThread:(DVBThread *)thread boardCode:(NSString *)boardCode;
+ (void)pushThreadFrom:(UIViewController *)viewController withThreadNum:(NSString *)threadNum boardCode:(NSString *)boardCode;
+ (void)openCreateThreadFrom:(UIViewController *)viewController boardCode:(NSString *)boardCode;

@end
