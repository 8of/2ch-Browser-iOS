//
//  DVBPostStyler.h
//  dvach-browser
//
//  Created by Andrey Konstantinov on 17/12/16.
//  Copyright © 2016 8of. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DVBPostStyler : NSObject

+ (UIColor *)postCellBackgroundColor;
+ (UIColor *)postCellInsideBackgroundColor;
+ (UIColor *)textColor;
+ (CGColorRef)borderColor;

+ (CGFloat)mediaSize;
+ (CGFloat)elementInset;
+ (CGFloat)innerInset;
+ (CGFloat)cornerRadius;

+ (BOOL)ageCheckNotPassed;

@end
