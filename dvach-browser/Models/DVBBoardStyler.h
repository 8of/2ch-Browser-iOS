//
//  DVBBoardStyler.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 16/11/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DVBBoardStyler : NSObject

#pragma mark - Thread list

+ (UIColor *)threadCellBackgroundColor;
+ (UIColor *)threadCellInsideBackgroundColor;
+ (UIColor *)textColor;
+ (CGColorRef)borderColor;

+ (CGFloat)mediaSize;
+ (CGFloat)elementInset;
+ (CGFloat)cornerRadius;

@end
